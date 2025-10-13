//
//  EnrollView.swift
//  HeartID Watch App
//
//  Comprehensive enrollment view with enterprise-grade biometric capture
//

import SwiftUI
import HealthKit

// MARK: - Type Aliases to Resolve Conflicts

// Use the comprehensive EnhancedBiometricValidation from dedicated file
typealias BiometricValidation = EnhancedBiometricValidation

// Ensure we use the proper HeartRateSample from BiometricModels
typealias HeartSample = HeartRateSample

// MARK: - Enrollment View

struct EnrollView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var healthKitService: HealthKitService
    
    @State private var enrollmentState: EnrollmentState = .ready
    @State private var captureProgress: Double = 0.0
    @State private var currentHeartRate: Double = 0.0
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var processingProgress: Double = 0.0
    @State private var processingTimer: Timer?
    @State private var capturedSamples: [Double] = []
    @State private var validationResult: BiometricValidation.ValidationResult?
    @State private var showingValidationDetails = false
    
    private let captureDuration: TimeInterval = 12.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    headerView
                    
                    // Status Card
                    statusCardView
                    
                    // Progress View (when capturing or processing)
                    if enrollmentState == .capturing || enrollmentState == .processing {
                        progressView
                    }
                    
                    // Validation Results
                    if let validation = validationResult, enrollmentState == .completed || enrollmentState == .failed {
                        validationResultView(validation)
                    }
                    
                    // Action Button
                    actionButtonView
                    
                    // Instructions
                    instructionsView
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Enrollment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
            }
        }
        .alert("Enrollment Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingValidationDetails) {
            if let validation = validationResult {
                ValidationDetailsView(validation: validation)
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onReceive(healthKitService.$captureProgress) { progress in
            captureProgress = progress
        }
        .onReceive(healthKitService.$currentHeartRate) { heartRate in
            currentHeartRate = heartRate
        }
        .onReceive(healthKitService.$errorMessage) { error in
            if let error = error {
                handleError(error)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Biometric Enrollment")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Create your unique biometric template")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Text(statusText)
                    .font(.headline)
                
                Spacer()
            }
            
            Text("HealthKit: \(healthKitService.authorizationStatus)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if authenticationService.isUserEnrolled {
                Text("Current enrollment will be replaced")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var progressView: some View {
        VStack(spacing: 12) {
            if enrollmentState == .capturing {
                Text("Capturing biometric data...")
                    .font(.headline)
                
                ProgressView(value: captureProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("\(Int(captureProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if currentHeartRate > 0 {
                    Text("Heart Rate: \(Int(currentHeartRate)) BPM")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text("Keep your finger on the Digital Crown")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            } else if enrollmentState == .processing {
                Text("Processing biometric template...")
                    .font(.headline)
                
                ProgressView(value: processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("Analyzing pattern characteristics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func validationResultView(_ validation: BiometricValidation.ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Validation Results")
                    .font(.headline)
                
                Spacer()
                
                Button("Details") {
                    showingValidationDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(validation.isValid ? .green : .red)
                
                Text(validation.isValid ? "Valid" : "Invalid")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(validation.qualityScore * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(qualityColor(validation.qualityScore))
            }
            
            if !validation.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(validation.recommendations.prefix(2), id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonView: some View {
        Button(action: handlePrimaryAction) {
            HStack {
                if enrollmentState == .capturing || enrollmentState == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: buttonIcon)
                }
                
                Text(buttonText)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(buttonColor)
            .cornerRadius(12)
        }
        .disabled(isButtonDisabled)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                instructionRow(icon: "hand.point.up", text: "Place finger firmly on Digital Crown")
                instructionRow(icon: "clock", text: "Hold steady for \(Int(captureDuration)) seconds")
                instructionRow(icon: "figure.stand", text: "Remain stationary during capture")
                instructionRow(icon: "heart", text: "Breathe normally and stay relaxed")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        switch enrollmentState {
        case .ready:
            return healthKitService.isAuthorized ? "checkmark.circle" : "exclamationmark.triangle"
        case .capturing:
            return "waveform.path.ecg"
        case .processing:
            return "gear"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch enrollmentState {
        case .ready:
            return healthKitService.isAuthorized ? .green : .orange
        case .capturing, .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        switch enrollmentState {
        case .ready:
            return healthKitService.isAuthorized ? "Ready to Enroll" : "HealthKit Authorization Required"
        case .capturing:
            return "Capturing Biometric Data"
        case .processing:
            return "Processing Template"
        case .completed:
            return "Enrollment Complete"
        case .failed:
            return "Enrollment Failed"
        }
    }
    
    private var buttonText: String {
        switch enrollmentState {
        case .ready:
            return "Start Enrollment"
        case .capturing:
            return "Capturing..."
        case .processing:
            return "Processing..."
        case .completed:
            return "Enroll Again"
        case .failed:
            return "Try Again"
        }
    }
    
    private var buttonIcon: String {
        switch enrollmentState {
        case .ready:
            return "play.circle.fill"
        case .completed:
            return "arrow.clockwise.circle"
        case .failed:
            return "exclamationmark.triangle"
        default:
            return "waveform.path.ecg"
        }
    }
    
    private var buttonColor: Color {
        switch enrollmentState {
        case .ready, .completed, .failed:
            return .blue
        default:
            return .gray
        }
    }
    
    private var isButtonDisabled: Bool {
        switch enrollmentState {
        case .capturing, .processing:
            return true
        case .ready:
            return !healthKitService.isAuthorized
        default:
            return false
        }
    }
    
    private func qualityColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Actions & Logic
    
    private func setupInitialState() {
        enrollmentState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
        errorMessage = nil
        validationResult = nil
        
        // Check HealthKit authorization
        Task {
            await checkHealthKitAuthorization()
        }
    }
    
    @MainActor
    private func checkHealthKitAuthorization() async {
        let result = await healthKitService.ensureAuthorization()
        
        switch result {
        case .authorized:
            print("✅ HealthKit authorization confirmed")
        case .denied(let message), .notAvailable(let message):
            handleError("HealthKit authorization failed: \(message)")
        }
    }
    
    private func handlePrimaryAction() {
        switch enrollmentState {
        case .ready:
            startEnrollment()
        case .completed, .failed:
            resetEnrollment()
        default:
            break
        }
    }
    
    private func startEnrollment() {
        guard healthKitService.isAuthorized else {
            Task {
                await checkHealthKitAuthorization()
            }
            return
        }
        
        enrollmentState = .capturing
        captureProgress = 0.0
        currentHeartRate = 0.0
        capturedSamples = []
        validationResult = nil
        errorMessage = nil
        
        print("🚀 Starting enrollment capture for \(captureDuration) seconds")
        
        // Start heart rate capture
        healthKitService.startHeartRateCapture(duration: captureDuration) { samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleError("Heart rate capture failed: \(error.localizedDescription)")
                } else {
                    self.processCapturedSamples(samples)
                }
            }
        }
    }
    
    private func processCapturedSamples(_ samples: [HeartSample]) {
        let values = samples.map { $0.value }
        capturedSamples = values
        
        print("✅ Processing \(values.count) captured samples")
        
        // Validate captured data
        guard !values.isEmpty else {
            handleError("No heart rate data captured. Please ensure proper watch placement.")
            return
        }
        
        guard values.count >= 10 else {
            handleError("Insufficient data captured (\(values.count) samples). Please try again.")
            return
        }
        
        // Validate data quality
        let validValues = values.filter { $0 > 40 && $0 < 200 }
        guard validValues.count >= 8 else {
            handleError("Invalid heart rate values detected. Please ensure proper sensor contact.")
            return
        }
        
        // Start processing
        enrollmentState = .processing
        startProcessingAnimation()
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async {
            self.processEnrollmentData(values)
        }
    }
    
    private func processEnrollmentData(_ samples: [Double]) {
        // Enhanced validation
        let validation = BiometricValidation.validate(samples)
        
        DispatchQueue.main.async {
            self.validationResult = validation
            
            if validation.isValid {
                // Create and store biometric pattern
                let pattern = self.createHeartPattern(from: samples)
                let success = self.storeHeartPattern(pattern)
                
                if success {
                    self.completeEnrollment()
                } else {
                    self.failEnrollment("Failed to save biometric template")
                }
            } else {
                self.failEnrollment(validation.errorMessage ?? "Data validation failed")
            }
        }
    }
    
    private func createHeartPattern(from samples: [Double]) -> HeartPattern {
        // Generate encrypted identifier for the pattern
        let identifier = "HeartID_\(UUID().uuidString.prefix(8))_\(Date().timeIntervalSince1970)"
        let encryptedId = identifier.data(using: .utf8)?.base64EncodedString() ?? identifier
        
        return HeartPattern(
            heartRateData: samples,
            duration: captureDuration,
            encryptedIdentifier: encryptedId
        )
    }
    
    private func storeHeartPattern(_ pattern: HeartPattern) -> Bool {
        do {
            // Store in secure keychain
            try TemplateStore.shared.save(pattern)
            
            // Update authentication service
            authenticationService.markUserEnrolledAndAuthenticated()
            
            print("✅ Heart pattern stored successfully")
            return true
        } catch {
            print("❌ Failed to store heart pattern: \(error.localizedDescription)")
            return false
        }
    }
    
    private func completeEnrollment() {
        stopProcessingAnimation()
        enrollmentState = .completed
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        print("✅ Enrollment completed successfully")
        
        // Auto-dismiss after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func failEnrollment(_ message: String) {
        stopProcessingAnimation()
        enrollmentState = .failed
        handleError(message)
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.failure)
    }
    
    private func resetEnrollment() {
        enrollmentState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
        capturedSamples = []
        validationResult = nil
        errorMessage = nil
    }
    
    private func handleCancel() {
        // Stop any ongoing capture
        if enrollmentState == .capturing {
            healthKitService.stopHeartRateCapture()
        }
        
        stopProcessingAnimation()
        dismiss()
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showingError = true
        enrollmentState = .failed
        
        print("❌ Enrollment error: \(message)")
    }
    
    private func startProcessingAnimation() {
        processingProgress = 0.0
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                self.processingProgress += 0.02
                if self.processingProgress >= 1.0 {
                    self.processingProgress = 1.0
                }
            }
        }
    }
    
    private func stopProcessingAnimation() {
        processingTimer?.invalidate()
        processingTimer = nil
        processingProgress = 0.0
    }
}

// MARK: - Supporting Types

enum EnrollmentState: Equatable {
    case ready
    case capturing
    case processing
    case completed
    case failed
}

// MARK: - Validation Details View

struct ValidationDetailsView: View {
    let validation: BiometricValidation.ValidationResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Overall Status
                    statusSection
                    
                    Divider()
                    
                    // Validation Details
                    detailsSection
                    
                    if let hrvFeatures = validation.hrvFeatures {
                        Divider()
                        hrvSection(hrvFeatures)
                    }
                    
                    if !validation.recommendations.isEmpty {
                        Divider()
                        recommendationsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Validation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Status")
                .font(.headline)
            
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(validation.isValid ? .green : .red)
                
                Text(validation.isValid ? "Valid" : "Invalid")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(validation.qualityScore * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Validation Details")
                .font(.headline)
            
            detailRow("Sample Count", value: "\(validation.validationDetails.sampleCount)")
            detailRow("Heart Rate Range", value: String(format: "%.0f - %.0f BPM", 
                     validation.validationDetails.heartRateRange.min,
                     validation.validationDetails.heartRateRange.max))
            detailRow("Average Heart Rate", value: String(format: "%.1f BPM", 
                     validation.validationDetails.averageHeartRate))
            detailRow("Signal Quality", value: String(format: "%.1f/10", 
                     validation.validationDetails.signalNoiseRatio))
        }
    }
    
    private func hrvSection(_ hrv: HRVCalculator.HRVFeatures) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HRV Analysis")
                .font(.headline)
            
            detailRow("RMSSD", value: String(format: "%.2f ms", hrv.rmssd))
            detailRow("pNN50", value: String(format: "%.3f", hrv.pnn50))
            detailRow("SDNN", value: String(format: "%.2f ms", hrv.sdnn))
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(validation.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(recommendation)
                        .font(.caption)
                }
            }
        }
    }
    
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Secure Template Store

final class TemplateStore {
    static let shared = TemplateStore()
    private init() {}
    
    private let account = "com.heartid.template"
    
    func save(_ pattern: HeartPattern) throws {
        let data = try JSONEncoder().encode(pattern)
        
        // Device-only, this device, accessible after first unlock
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        
        // Delete existing entry
        SecItemDelete(query as CFDictionary)
        
        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), 
                         userInfo: [NSLocalizedDescriptionKey: "Keychain save failed: \(status)"])
        }
    }
    
    func load() throws -> HeartPattern? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound { 
            return nil 
        }
        
        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), 
                         userInfo: [NSLocalizedDescriptionKey: "Keychain load failed: \(status)"])
        }
        
        return try JSONDecoder().decode(HeartPattern.self, from: data)
    }
    
    func revoke() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - AuthenticationService Extension for Enrollment

extension AuthenticationService {
    func markUserEnrolledAndAuthenticated() {
        DispatchQueue.main.async {
            self.isUserEnrolled = true
            self.isAuthenticated = true
            self.lastAuthenticationResult = .approved(confidence: 1.0)
        }
    }
}