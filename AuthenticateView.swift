//
//  AuthenticateView.swift
//  HeartID Watch App
//
//  Comprehensive authentication view with enterprise-grade security
//

import SwiftUI
import HealthKit

// MARK: - Authentication View

struct AuthenticateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var authenticationState: AuthenticationState = .ready
    @State private var captureProgress: Double = 0.0
    @State private var currentHeartRate: Double = 0.0
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var authenticationResult: AuthenticationResult?
    @State private var capturedSamples: [Double] = []
    @State private var showingResultDetails = false
    @State private var attemptCount = 0
    
    private let captureDuration: TimeInterval = 8.0
    private let maxAttempts = 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    headerView
                    
                    // Status Card
                    statusCardView
                    
                    // Progress View (when authenticating)
                    if authenticationState == .capturing || authenticationState == .processing {
                        progressView
                    }
                    
                    // Action Button
                    actionButton
                    
                    // Result Display
                    if let result = authenticationResult {
                        resultView(result)
                    }
                    
                    // Status Information
                    statusInformation
                }
                .padding()
            }
            .navigationTitle("Authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if authenticationState == .capturing {
                            stopAuthentication()
                        }
                        dismiss()
                    }
                }
            }
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showingResultDetails) {
            AuthenticationResultDetailView(
                result: authenticationResult,
                capturedSamples: capturedSamples
            )
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: authenticationState.iconName)
                .font(.system(size: 40))
                .foregroundColor(authenticationState.iconColor)
                .symbolEffect(.pulse, isActive: authenticationState == .capturing)
            
            Text("Authentication")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(authenticationState.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var statusCardView: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Status", systemImage: "heart.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Enrollment:")
                    Spacer()
                    Text(authenticationService.isUserEnrolled ? "✓ Complete" : "⚠️ Required")
                        .foregroundColor(authenticationService.isUserEnrolled ? .green : .orange)
                }
                
                HStack {
                    Text("HealthKit:")
                    Spacer()
                    Text(healthKitService.isAuthorized ? "✓ Authorized" : "⚠️ Not Authorized")
                        .foregroundColor(healthKitService.isAuthorized ? .green : .orange)
                }
                
                if attemptCount > 0 {
                    HStack {
                        Text("Attempts:")
                        Spacer()
                        Text("\(attemptCount)/\(maxAttempts)")
                            .foregroundColor(attemptCount >= maxAttempts ? .red : .blue)
                    }
                }
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var progressView: some View {
        VStack(spacing: 16) {
            // Heart rate display
            if authenticationState == .capturing && currentHeartRate > 0 {
                VStack(spacing: 4) {
                    Text("\(Int(currentHeartRate))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress indicator
            if authenticationState == .capturing {
                CircularProgressView(progress: captureProgress)
                    .frame(width: 80, height: 80)
                
                Text("Keep finger steady...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if authenticationState == .processing {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Processing pattern...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button(action: handlePrimaryAction) {
            HStack {
                Image(systemName: authenticationState.buttonIcon)
                Text(authenticationState.buttonTitle)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(authenticationState.buttonColor)
            .cornerRadius(25)
        }
        .disabled(!authenticationState.isActionEnabled || !isReadyForAuthentication)
    }
    
    @ViewBuilder
    private var statusInformation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication Information")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("• Place finger on Digital Crown")
            Text("• Hold steady for \(Int(captureDuration)) seconds")
            Text("• Ensure good sensor contact")
            
            if attemptCount > 0 {
                Text("• \(maxAttempts - attemptCount) attempts remaining")
                    .foregroundColor(attemptCount >= maxAttempts - 1 ? .red : .secondary)
            }
        }
        .font(.caption)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func resultView(_ result: AuthenticationResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.iconName)
                    .font(.title2)
                    .foregroundColor(result.iconColor)
                
                VStack(alignment: .leading) {
                    Text(result.title)
                        .font(.headline)
                        .foregroundColor(result.iconColor)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Details") {
                    showingResultDetails = true
                }
                .font(.caption)
            }
            
            // Action buttons based on result
            HStack {
                if result.requiresRetry && attemptCount < maxAttempts {
                    Button("Try Again") {
                        resetForNewAttempt()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if result.isSuccessful {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(result.backgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var isReadyForAuthentication: Bool {
        authenticationService.isUserEnrolled && 
        healthKitService.isAuthorized &&
        attemptCount < maxAttempts
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() {
        switch authenticationState {
        case .ready:
            startAuthentication()
        case .capturing:
            stopAuthentication()
        case .processing, .completed, .failed:
            resetForNewAttempt()
        }
    }
    
    private func startAuthentication() {
        guard isReadyForAuthentication else {
            if !authenticationService.isUserEnrolled {
                showError("Please enroll first before authenticating")
            } else if !healthKitService.isAuthorized {
                showError("HealthKit authorization required")
            } else {
                showError("Maximum attempts reached")
            }
            return
        }
        
        debugLog.auth("🔐 Starting authentication attempt \(attemptCount + 1)")
        
        authenticationState = .capturing
        captureProgress = 0.0
        currentHeartRate = 0.0
        capturedSamples = []
        attemptCount += 1
        
        // Start heart rate capture
        Task {
            let result = await healthKitService.startHeartRateCapture(duration: captureDuration)
            
            await MainActor.run {
                self.authenticationState = .processing
                
                switch result {
                case .success(let heartRateData):
                    self.capturedSamples = heartRateData
                    self.processAuthentication(with: heartRateData)
                    
                case .failure(let error):
                    self.showError("Capture failed: \(error.localizedDescription)")
                    self.authenticationState = .failed
                }
            }
        }
        
        // Update progress during capture
        startProgressTimer()
    }
    
    private func stopAuthentication() {
        debugLog.auth("⏹️ Stopping authentication capture")
        
        healthKitService.stopHeartRateCapture()
        authenticationState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
    }
    
    private func processAuthentication(with heartRateData: [Double]) {
        debugLog.auth("🧮 Processing authentication with \(heartRateData.count) samples")
        
        // Perform authentication
        let result = authenticationService.completeAuthentication(with: heartRateData)
        
        DispatchQueue.main.async {
            self.authenticationResult = result
            
            if result.isSuccessful {
                self.authenticationState = .completed
                debugLog.auth("✅ Authentication successful")
            } else if result.requiresRetry && self.attemptCount < self.maxAttempts {
                self.authenticationState = .failed
                debugLog.auth("⚠️ Authentication failed, retry available")
            } else {
                self.authenticationState = .failed
                debugLog.auth("❌ Authentication failed, maximum attempts reached")
            }
        }
    }
    
    private func startProgressTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.authenticationState == .capturing {
                    self.captureProgress += 0.1 / self.captureDuration
                    
                    // Update current heart rate from service
                    self.currentHeartRate = self.healthKitService.currentHeartRate
                    
                    if self.captureProgress >= 1.0 {
                        timer.invalidate()
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
        
        // Auto-cleanup timer
        DispatchQueue.main.asyncAfter(deadline: .now() + captureDuration + 1) {
            timer.invalidate()
        }
    }
    
    private func resetForNewAttempt() {
        authenticationState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
        authenticationResult = nil
        errorMessage = nil
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Authentication State

enum AuthenticationState {
    case ready
    case capturing
    case processing
    case completed
    case failed
    
    var iconName: String {
        switch self {
        case .ready: return "person.badge.key.fill"
        case .capturing: return "waveform.path.ecg"
        case .processing: return "gear.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .ready: return .blue
        case .capturing: return .green
        case .processing: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var description: String {
        switch self {
        case .ready: return "Ready for authentication"
        case .capturing: return "Capturing heart pattern"
        case .processing: return "Processing authentication"
        case .completed: return "Authentication successful"
        case .failed: return "Authentication failed"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .ready: return "Authenticate"
        case .capturing: return "Stop"
        case .processing: return "Processing..."
        case .completed, .failed: return "Try Again"
        }
    }
    
    var buttonIcon: String {
        switch self {
        case .ready: return "play.fill"
        case .capturing: return "stop.fill"
        case .processing: return "ellipsis"
        case .completed, .failed: return "arrow.clockwise"
        }
    }
    
    var buttonColor: Color {
        switch self {
        case .ready: return .blue
        case .capturing: return .red
        case .processing: return .gray
        case .completed: return .green
        case .failed: return .orange
        }
    }
    
    var isActionEnabled: Bool {
        switch self {
        case .processing: return false
        default: return true
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Authentication Result Extensions

extension AuthenticationResult {
    var iconName: String {
        switch self {
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .retry: return "arrow.clockwise.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .pending: return "clock.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .approved: return .green
        case .denied: return .red
        case .retry: return .orange
        case .error: return .red
        case .pending: return .blue
        }
    }
    
    var title: String {
        switch self {
        case .approved: return "Authentication Successful"
        case .denied: return "Access Denied"
        case .retry: return "Try Again"
        case .error: return "Error"
        case .pending: return "Processing"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .approved: return Color.green.opacity(0.1)
        case .denied: return Color.red.opacity(0.1)
        case .retry: return Color.orange.opacity(0.1)
        case .error: return Color.red.opacity(0.1)
        case .pending: return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Authentication Result Detail View

struct AuthenticationResultDetailView: View {
    let result: AuthenticationResult?
    let capturedSamples: [Double]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let result = result {
                    VStack(spacing: 12) {
                        Image(systemName: result.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(result.iconColor)
                        
                        Text(result.title)
                            .font(.headline)
                        
                        Text(result.message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                // Sample statistics
                if !capturedSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capture Statistics")
                            .font(.headline)
                        
                        HStack {
                            Text("Samples:")
                            Spacer()
                            Text("\(capturedSamples.count)")
                        }
                        
                        HStack {
                            Text("Average BPM:")
                            Spacer()
                            Text("\(Int(capturedSamples.reduce(0, +) / Double(capturedSamples.count)))")
                        }
                        
                        HStack {
                            Text("Range:")
                            Spacer()
                            Text("\(Int(capturedSamples.min() ?? 0)) - \(Int(capturedSamples.max() ?? 0))")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Authentication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}