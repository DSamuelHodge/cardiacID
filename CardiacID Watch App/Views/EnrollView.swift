// HeartID – Biometric ID Enrollment & Verification (watchOS)
// Clean-break capture windows + per-iteration HKWorkoutSession + on-device template matching
// Focus: biometric template creation, protected storage, on-device comparison, revocation
// Notes: Avoid Water Lock mid-flow to reduce lifecycle complexity. Use device-only Keychain.

import SwiftUI
import Foundation
import HealthKit
import Combine
import Security

// MARK: - Biometric Template Model
struct HeartTemplate: Codable, Equatable {
    // Minimal, privacy-preserving features (example):
    // - mean HR, std dev, normalized slope energy, sample count
    // - optional coarse histogram to reduce reversibility
    let version: Int
    let mean: Double
    let stdev: Double
    let slopeEnergy: Double
    let count: Int
    let histogram: [Double] // coarse 6-bin normalized histogram

    static let currentVersion = 1
}

// MARK: - Feature Extraction (privacy conscious)
enum FeatureExtractor {
    static func features(from bpm: [Double]) -> HeartTemplate? {
        guard bpm.count >= 8 else { return nil }
        let n = Double(bpm.count)
        let mean = bpm.reduce(0,+) / n
        let varTerm = bpm.map { pow($0 - mean, 2) }.reduce(0,+) / n
        let stdev = sqrt(max(0, varTerm))
        // slope energy: sum((x[i]-x[i-1])^2) / n
        let diffs = zip(bpm.dropFirst(), bpm).map { $0 - $1 }
        let slopeEnergy = diffs.map { $0*$0 }.reduce(0,+) / n
        // coarse histogram in 6 bins around mean ± 3*stdev (clip)
        let span = max(1.0, 6.0*max(stdev, 1.0))
        let minV = mean - span/2
        let maxV = mean + span/2
        var bins = Array(repeating: 0.0, count: 6)
        for v in bpm {
            let clamped = min(max(v, minV), maxV)
            let t = (clamped - minV) / (maxV - minV)
            let idx = min(5, max(0, Int(floor(t * 6.0))))
            bins[idx] += 1.0
        }
        let hist = bins.map { $0 / n }
        return HeartTemplate(version: HeartTemplate.currentVersion, mean: mean, stdev: stdev, slopeEnergy: slopeEnergy, count: Int(n), histogram: hist)
    }
}

// MARK: - Matcher (on-device)
struct HeartMatcher {
    struct Result { let score: Double; let passed: Bool }

    /// Compare a live sample against enrolled template.
    /// Returns a distance-like score (lower is closer). Threshold tuned experimentally.
    static func match(live: HeartTemplate, enrolled: HeartTemplate, threshold: Double = 0.42) -> Result {
        // Z-normalize differences to balance units
        func nz(_ x: Double) -> Double { x.isFinite ? x : 0 }
        let dMean = abs(live.mean - enrolled.mean)
        let dStd  = abs(live.stdev - enrolled.stdev)
        let dSE   = abs(live.slopeEnergy - enrolled.slopeEnergy)
        let dHist = zip(live.histogram, enrolled.histogram).map { abs($0 - $1) }.reduce(0,+) // L1
        // scale to roughly comparable ranges
        let s = 0.02 * nz(dMean) + 0.03 * nz(dStd) + 1.0 * nz(dSE) + 0.4 * nz(dHist)
        return .init(score: s, passed: s <= threshold)
    }
}

// MARK: - Secure Template Store (device-only Keychain)
final class TemplateStore {
    static let shared = TemplateStore()
    private init() {}

    private let account = "com.argos.heartid.template"

    func save(_ template: HeartTemplate) throws {
        let data = try JSONEncoder().encode(template)
        // Device-only, this device, accessible after first unlock
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Keychain save failed: \(status)"])
        }
    }

    func load() throws -> HeartTemplate? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Keychain load failed: \(status)"])
        }
        return try JSONDecoder().decode(HeartTemplate.self, from: data)
    }

    func revoke() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Verification Utilities (keeps your variables but focuses on biometric flow)
extension EnrollView {
    func makeTemplate(from values: [Double]) -> HeartTemplate? {
        return FeatureExtractor.features(from: values)
    }

    func storeBaseline(_ t: HeartTemplate) {
        do { try TemplateStore.shared.save(t) } catch { self.errorMessage = error.localizedDescription }
    }

    func loadBaseline() -> HeartTemplate? {
        do { return try TemplateStore.shared.load() } catch { self.errorMessage = error.localizedDescription; return nil }
    }
}

// MARK: - AuthenticationService Extension
extension AuthenticationService {
    /// Mark user as enrolled and authenticated (missing method)
    func markEnrolledAndAuthenticated() {
        self.isUserEnrolled = true
        self.isAuthenticated = true
        self.lastAuthenticationResult = .approved
        print("✅ User marked as enrolled and authenticated")
    }
}

// MARK: - EnrollView (biometric-first wiring)
struct EnrollView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var dataManager: DataManager

    @State private var enrollmentState: EnrollmentState = .ready
    @State private var captureProgress: Double = 0
    @State private var currentHeartRate: Double = 0
    @State private var errorMessage: String?
    @State private var processingProgress: Double = 0
    @State private var processingTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var countdownValue = 3

    // Verification flow states (kept from your code)
    @State private var baselinePattern: [Double] = []
    @State private var verificationResult: VerificationResult?
    @State private var showingRangeOptions = false
    @State private var relaxationCountdown = 120 // 2 minutes
    @State private var relaxationTimer: Timer?
    @State private var testHeartRate: Double = 0
    @State private var heartRateDifference: Double = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    Text("Enroll").font(.headline)
                    Text(helperSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // State-driven content
                Group {
                    switch enrollmentState {
                    case .ready:
                        Text("Ready to start").font(.caption)
                    case .initializing:
                        ProgressView("Initializing...")
                    case .countdown(let n):
                        VStack {
                            Text("\(n)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.orange)
                            Text("Get Ready").font(.caption)
                        }
                    case .capturing:
                        CapturingStateView(progress: captureProgress, heartRate: currentHeartRate)
                    case .processing:
                        ProcessingStateView(progress: processingProgress, title: "Creating Template")
                    case .verification:
                        ProcessingStateView(progress: processingProgress, title: "Verifying")
                    case .verificationComplete:
                        ResultStateView(result: authenticationService.lastAuthenticationResult ?? .pending, retryCount: 0)
                    case .completed, .rangeOptions, .relaxation, .exercise, .rangeTest, .finalComplete:
                        Text("Complete").font(.caption)
                    case .error(let msg):
                        Text(msg).font(.caption).foregroundColor(.red)
                    }
                }

                // Action row
                HStack {
                    if case .ready = enrollmentState {
                        Button("Start") { startEnrollment() }
                            .buttonStyle(.borderedProminent)
                    } else if case .error = enrollmentState {
                        Button("Close") { dismiss() }.buttonStyle(.bordered)
                    } else {
                        Button("Cancel") { dismiss() }.buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .navigationTitle("Enroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        // Keep progress/HR in sync
        .onReceive(healthKitService.$captureProgress) { captureProgress = $0 }
        .onReceive(healthKitService.$currentHeartRate) { currentHeartRate = $0 }
        .onReceive(healthKitService.$errorMessage) { if let e = $0 { enrollmentState = .error(e) } }
        // Check HealthKit authorization on appear
        .onAppear {
            Task { @MainActor in
                await ensureHealthKitAuthorization()
            }
        }
    }
    
    @MainActor
    private func ensureHealthKitAuthorization() async {
        guard !healthKitService.isAuthorized else { return }
        
        // Request authorization synchronously
        healthKitService.requestAuthorization()
        
        // Wait a moment for authorization to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if !healthKitService.isAuthorized {
            enrollmentState = .error("HealthKit authorization required. Please enable in Settings.")
        }
    }

    private var helperSubtitle: String {
        switch enrollmentState {
        case .ready: return "We'll capture a short baseline, then verify it."
        case .initializing: return "Preparing sensors"
        case .countdown: return "Place your finger on the Digital Crown"
        case .capturing: return "Keep still during capture"
        case .processing: return "Analyzing pattern"
        case .verification: return "Verifying against baseline"
        case .verificationComplete: return "Reviewing result"
        case .completed, .rangeOptions, .relaxation, .exercise, .rangeTest, .finalComplete: return ""
        case .error: return ""
        }
    }

    // MARK: - HealthKit Authorization
    private func checkHealthKitAuthorization() {
        print("🔍 Checking HealthKit authorization...")
        
        if !healthKitService.isAuthorized {
            print("⚠️ HealthKit not authorized, requesting permission...")
            healthKitService.requestAuthorization()
            
            // Wait a moment for authorization to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !self.healthKitService.isAuthorized {
                    self.enrollmentState = .error("HealthKit authorization required. Please enable in Settings.")
                }
            }
        } else {
            print("✅ HealthKit is authorized")
        }
    }

    // MARK: - Enrollment Flow
    private func startEnrollment() {
        print("🚀 Starting enrollment process...")
        
        // Check HealthKit authorization before starting
        guard healthKitService.isAuthorized else {
            enrollmentState = .error("HealthKit authorization required. Please enable in Settings.")
            return
        }
        
        enrollmentState = .initializing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.startCountdown() }
    }

    private func startCountdown() {
        countdownValue = 3
        enrollmentState = .countdown(countdownValue)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdownValue -= 1
            if countdownValue > 0 { enrollmentState = .countdown(countdownValue) }
            else { timer.invalidate(); countdownTimer = nil; startCapture() }
        }
    }

    private func startCapture() {
        enrollmentState = .capturing
        Task { await captureEnrollmentWindow() }
    }

    @MainActor
    private func captureEnrollmentWindow() async {
        // Validate state before capture
        guard enrollmentState == .capturing else {
            print("❌ Invalid state for enrollment capture: \(enrollmentState)")
            enrollmentState = .error("Invalid capture state")
            return
        }
        
        do {
            let duration: TimeInterval = 12.0 // Increased for better sensor engagement
            print("📊 Starting enrollment capture for \(duration) seconds")
            
            // Check HealthKit authorization again before capture
            guard healthKitService.isAuthorized else {
                enrollmentState = .error("HealthKit authorization lost during capture")
                return
            }
            
            // Clear any existing samples before starting new capture
            healthKitService.heartRateSamples.removeAll()
            
            // Use the HealthKitService from Services
            healthKitService.startHeartRateCapture(duration: duration)
            
            // Wait for capture to complete with buffer time
            try await Task.sleep(nanoseconds: UInt64((duration + 2.0) * 1_000_000_000))
            
            // Ensure capture has fully stopped (wait, don't early return)
            var waitCount = 0
            while healthKitService.isCapturing && waitCount < 20 { // Max 6 seconds wait
                print("⏳ Waiting for capture to stop… (\(waitCount + 1)/20)")
                try await Task.sleep(nanoseconds: 300_000_000)
                waitCount += 1
            }
            
            if healthKitService.isCapturing {
                print("⚠️ Capture still running after timeout, forcing stop")
                healthKitService.stopHeartRateCapture()
                // Give a moment for the stop to take effect
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            
            let values = healthKitService.heartRateSamples.map { $0.value }
            print("✅ Captured \(values.count) heart rate samples: \(values.prefix(5))...")
            
            // Enhanced validation with more detailed error messages
            guard !values.isEmpty else {
                enrollmentState = .error("No heart rate data captured. Ensure watch is properly fitted and try again.")
                return
            }
            
            guard values.count >= 8 else {
                enrollmentState = .error("Insufficient heart rate data (\(values.count) samples). Need at least 8 samples. Please try again.")
                return
            }
            
            // Validate data quality - check for reasonable heart rate values
            let validValues = values.filter { $0 > 30 && $0 < 220 }
            guard validValues.count >= 8 else {
                enrollmentState = .error("Invalid heart rate values detected. Please ensure proper sensor contact.")
                return
            }
            
            baselinePattern = values
            if let tpl = makeTemplate(from: values) { 
                storeBaseline(tpl)
                print("✅ Heart template created and stored successfully")
                
                // Verify template was actually saved
                if loadBaseline() != nil {
                    print("✅ Template verification successful")
                } else {
                    enrollmentState = .error("Template saved but verification failed")
                    return
                }
            } else {
                enrollmentState = .error("Failed to create heart template from captured data. Please try again.")
                return
            }
            
            // Give system time before completing enrollment
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            completeEnrollment()
        } catch {
            print("❌ Enrollment capture error: \(error.localizedDescription)")
            enrollmentState = .error("Capture failed: \(error.localizedDescription)")
        }
    }

    private func completeEnrollment() {
        enrollmentState = .processing
        processingProgress = 0
        if processingTimer == nil { startProcessingTimer() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.stopProcessingTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.startAutomaticVerification() }
        }
    }
    
    private func startProcessingTimer() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                processingProgress += 0.083 // Complete in 1.2 seconds (0.1 * 12 = 1.2)
                if processingProgress >= 1.0 {
                    processingProgress = 1.0
                }
            }
        }
    }
    
    private func stopProcessingTimer() {
        processingTimer?.invalidate()
        processingTimer = nil
        processingProgress = 0
    }

    // MARK: - Verification (biometric compare)
    private func startAutomaticVerification() {
        enrollmentState = .verification
        Task { await captureVerificationWindow() }
    }

    @MainActor
    private func captureVerificationWindow() async {
        do {
            let duration: TimeInterval = 10.0
            print("📊 Starting verification capture for \(duration) seconds")
            
            // Check HealthKit authorization before verification
            guard healthKitService.isAuthorized else {
                enrollmentState = .error("HealthKit authorization lost during verification")
                return
            }
            
            // Clear any existing samples before starting new capture
            healthKitService.heartRateSamples.removeAll()
            
            // Use the HealthKitService from Services
            healthKitService.startHeartRateCapture(duration: duration)
            
            // Wait for capture to complete
            try await Task.sleep(nanoseconds: UInt64((duration + 1.0) * 1_000_000_000))
            
            // Wait for capture to stop with timeout
            var waitCount = 0
            while healthKitService.isCapturing && waitCount < 15 { // Max 4.5 seconds wait
                print("⏳ Waiting for verification capture to stop… (\(waitCount + 1)/15)")
                try await Task.sleep(nanoseconds: 300_000_000)
                waitCount += 1
            }
            
            if healthKitService.isCapturing {
                print("⚠️ Verification capture still running after timeout, forcing stop")
                healthKitService.stopHeartRateCapture()
                // Give a moment for the stop to take effect
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            
            let values = healthKitService.heartRateSamples.map { $0.value }
            print("✅ Verification captured \(values.count) heart rate samples: \(values.prefix(5))...")
            
            // Enhanced validation for verification data
            guard !values.isEmpty else {
                enrollmentState = .error("No verification data captured. Please try again.")
                return
            }
            
            guard values.count >= 5 else {
                enrollmentState = .error("Insufficient verification data (\(values.count) samples). Please try again.")
                return
            }
            
            // Validate data quality
            let validValues = values.filter { $0 > 30 && $0 < 220 }
            guard validValues.count >= 3 else {
                enrollmentState = .error("Invalid heart rate values in verification data.")
                return
            }
            
            performVerification(with: values)
        } catch {
            print("❌ Verification capture error: \(error.localizedDescription)")
            enrollmentState = .error("Verification failed: \(error.localizedDescription)")
        }
    }

    private func performVerification(with current: [Double]) {
        // Prefer on-device matching against enrolled template in Keychain
        if let enrolled = loadBaseline(), let live = makeTemplate(from: current) {
            let result = HeartMatcher.match(live: live, enrolled: enrolled)
            verificationResult = VerificationResult(
                passed: result.passed,
                message: result.passed ? "Pattern verified successfully" : "Pattern verification failed (score: \(String(format: "%.3f", result.score)))",
                testType: nil,
                heartRate: current.last,
                difference: nil
            )
        } else {
            verificationResult = VerificationResult(passed: false, message: "Insufficient data for comparison", testType: nil, heartRate: nil, difference: nil)
        }

        // On success: mark enrolled, notify, and dismiss so Menu can open Settings
        if let vr = verificationResult, vr.passed {
            authenticationService.markEnrolledAndAuthenticated()
            NotificationCenter.default.post(name: .init("UserEnrolled"), object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
        }

        enrollmentState = .verificationComplete
    }

    // MARK: - (Optional) Range tests – unchanged behavior, left for your flow
    // ... keep your existing range test and timer helpers ...
}

// MARK: - Supporting Views
struct CapturingStateView: View {
    let progress: Double
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            Text("Heart Rate: \(Int(heartRate)) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


struct ResultStateView: View {
    let result: AuthenticationResult
    let retryCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(result.isSuccessful ? .green : .red)
            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Supporting Types
enum EnrollmentState: Equatable { 
    case ready, initializing, countdown(Int), capturing, processing, completed, verification, verificationComplete, rangeOptions, relaxation, exercise, rangeTest, finalComplete, error(String) 
}

struct VerificationResult { 
    let passed: Bool
    let message: String
    let testType: TestType?
    let heartRate: Double?
    let difference: Double? 
}

enum TestType { case lower, upper }

// MARK: - Missing AuthenticationResult Definition
enum AuthenticationResult: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case failed = "failed"
    case retryRequired = "retry_required"
    case systemUnavailable = "system_unavailable"
    
    var isSuccessful: Bool {
        return self == .approved
    }
    
    var requiresRetry: Bool {
        return self == .retryRequired
    }
    
    var message: String {
        switch self {
        case .pending:
            return "Authentication in progress"
        case .approved:
            return "Authentication successful"
        case .failed:
            return "Authentication failed"
        case .retryRequired:
            return "Please try again"
        case .systemUnavailable:
            return "System temporarily unavailable"
        }
    }
}
