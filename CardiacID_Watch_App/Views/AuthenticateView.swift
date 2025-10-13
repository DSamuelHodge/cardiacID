//
//  AuthenticateView.swift
//  HeartID Watch App
//
//  Enterprise-grade authentication view with biometric verification
//

import SwiftUI
import HealthKit

// MARK: - Type Aliases to Resolve Conflicts

// Use the comprehensive EnhancedBiometricValidation from dedicated file
typealias BiometricValidation = EnhancedBiometricValidation

// Use the unified type from TypeAliases.swift
// HeartRateSample is properly defined in HeartRateSample.swift

// MARK: - Authentication View

struct AuthenticateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var healthKitService: HealthKitService
    
    @State private var authenticationState: AuthenticationViewState = .ready
    @State private var captureProgress: Double = 0.0
    @State private var currentHeartRate: Double = 0.0
    @State private var retryCount = 0
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var processingProgress: Double = 0.0
    @State private var processingTimer: Timer?
    @State private var capturedSamples: [Double] = []
    @State private var authResult: AuthenticationResult?
    @State private var showingResult = false
    
    private let maxRetries = 3
    private let captureDuration: TimeInterval = 8.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    headerView
                    
                    // Status Display
                    statusDisplayView
                    
                    // Action Button
                    actionButtonView
                    
                    // Retry Information
                    if retryCount > 0 {
                        retryInfoView
                    }
                    
                    // Instructions
                    instructionsView
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
            }
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
            Button("Retry") {
                if retryCount < maxRetries {
                    resetAuthentication()
                    startAuthentication()
                } else {
                    showingError = false
                    authenticationState = .failed
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingResult) {
            if let result = authResult {
                AuthenticationResultView(result: result) {
                    showingResult = false
                    if result.isSuccessful {
                        dismiss()
                    } else {
                        resetAuthentication()
                    }
                }
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
            Image(systemName: "checkmark.shield")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Biometric Authentication")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Verify your identity using your heart pattern")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusDisplayView: some View {
        VStack(spacing: 16) {
            switch authenticationState {
            case .ready:
                readyStateView
            case .capturing:
                capturingStateView
            case .processing:
                processingStateView
            case .completed:
                completedStateView
            case .failed:
                failedStateView
            }
        }
        .padding()
        .background(stateBackgroundColor)
        .cornerRadius(12)
    }
    
    private var readyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.point.up")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("Ready to Authenticate")
                .font(.headline)
            
            Text("Place finger on Digital Crown")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var capturingStateView: some View {
        VStack(spacing: 12) {
            Text("Capturing Heart Pattern")
                .font(.headline)
            
            ProgressView(value: captureProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("\(Int(captureProgress * 100))% Complete")
                Spacer()
                if currentHeartRate > 0 {
                    Text("\(Int(currentHeartRate)) BPM")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Keep finger steady")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
    
    private var processingStateView: some View {
        VStack(spacing: 12) {
            Text("Analyzing Pattern")
                .font(.headline)
            
            ProgressView(value: processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Comparing with enrolled template")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var completedStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text("Authentication Successful")
                .font(.headline)
                .foregroundColor(.green)
            
            if let result = authResult {
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var failedStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            
            Text("Authentication Failed")
                .font(.headline)
                .foregroundColor(.red)
            
            if let result = authResult {
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var actionButtonView: some View {
        Button(action: handlePrimaryAction) {
            HStack {
                if authenticationState == .capturing || authenticationState == .processing {
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
    
    private var retryInfoView: some View {
        VStack(spacing: 8) {
            Text("Retry \(retryCount)/\(maxRetries)")
                .font(.caption)
                .foregroundColor(.orange)
            
            if retryCount >= maxRetries {
                Text("Maximum retries reached")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication Tips")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                instructionRow(icon: "hand.point.up", text: "Place finger on Digital Crown")
                instructionRow(icon: "clock", text: "Hold for \(Int(captureDuration)) seconds")
                instructionRow(icon: "figure.stand", text: "Stay still during capture")
                instructionRow(icon: "heart", text: "Breathe normally")
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
        }
    }
    
    // MARK: - Computed Properties
    
    private var stateBackgroundColor: Color {
        switch authenticationState {
        case .ready:
            return Color.blue.opacity(0.1)
        case .capturing, .processing:
            return Color.orange.opacity(0.1)
        case .completed:
            return Color.green.opacity(0.1)
        case .failed:
            return Color.red.opacity(0.1)
        }
    }
    
    private var buttonText: String {
        switch authenticationState {
        case .ready:
            return "Start Authentication"
        case .capturing:
            return "Capturing..."
        case .processing:
            return "Processing..."
        case .completed:
            return "Complete"
        case .failed:
            return retryCount < maxRetries ? "Try Again" : "Close"
        }
    }
    
    private var buttonIcon: String {
        switch authenticationState {
        case .ready:
            return "play.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return retryCount < maxRetries ? "arrow.clockwise.circle" : "xmark.circle"
        default:
            return "waveform.path.ecg"
        }
    }
    
    private var buttonColor: Color {
        switch authenticationState {
        case .ready:
            return .blue
        case .completed:
            return .green
        case .failed:
            return retryCount < maxRetries ? .orange : .red
        default:
            return .gray
        }
    }
    
    private var isButtonDisabled: Bool {
        switch authenticationState {
        case .capturing, .processing:
            return true
        case .ready:
            return !healthKitService.isAuthorized || !authenticationService.isUserEnrolled
        default:
            return false
        }
    }
    
    // MARK: - Actions & Logic
    
    private func setupInitialState() {
        authenticationState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
        errorMessage = nil
        authResult = nil
        
        // Check prerequisites
        checkPrerequisites()
    }
    
    private func checkPrerequisites() {
        guard authenticationService.isUserEnrolled else {
            handleError("No biometric template found. Please enroll first.")
            return
        }
        
        guard healthKitService.isAuthorized else {
            Task {
                await checkHealthKitAuthorization()
            }
            return
        }
    }
    
    @MainActor
    private func checkHealthKitAuthorization() async {
        let result = await healthKitService.ensureAuthorization()
        
        switch result {
        case .authorized:
            print("✅ HealthKit authorization confirmed")
        case .denied(let message), .notAvailable(let message):
            handleError("HealthKit authorization required: \(message)")
        }
    }
    
    private func handlePrimaryAction() {
        switch authenticationState {
        case .ready:
            startAuthentication()
        case .completed:
            dismiss()
        case .failed:
            if retryCount < maxRetries {
                resetAuthentication()
                startAuthentication()
            } else {
                dismiss()
            }
        default:
            break
        }
    }
    
    private func startAuthentication() {
        guard healthKitService.isAuthorized else {
            handleError("HealthKit authorization required")
            return
        }
        
        guard authenticationService.isUserEnrolled else {
            handleError("No biometric template found. Please enroll first.")
            return
        }
        
        authenticationState = .capturing
        captureProgress = 0.0
        currentHeartRate = 0.0
        capturedSamples = []
        authResult = nil
        errorMessage = nil
        
        print("🚀 Starting authentication capture for \(captureDuration) seconds")
        
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
        
        print("✅ Processing \(values.count) captured samples for authentication")
        
        // Validate captured data
        guard !values.isEmpty else {
            handleError("No heart rate data captured. Please ensure proper watch placement.")
            return
        }
        
        guard values.count >= 5 else {
            handleError("Insufficient data captured (\(values.count) samples). Please try again.")
            return
        }
        
        // Validate data quality
        let validValues = values.filter { $0 > 40 && $0 < 200 }
        guard validValues.count >= 3 else {
            handleError("Invalid heart rate values detected. Please ensure proper sensor contact.")
            return
        }
        
        // Start processing
        authenticationState = .processing
        startProcessingAnimation()
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async {
            self.performAuthentication(values)
        }
    }
    
    private func performAuthentication(_ samples: [Double]) {
        do {
            // Load enrolled template
            guard let enrolledPattern = try TemplateStore.shared.load() else {
                DispatchQueue.main.async {
                    self.handleError("No enrolled template found. Please enroll first.")
                }
                return
            }
            
            // Create current pattern
            let currentPattern = createHeartPattern(from: samples)
            
            // Compare patterns
            let similarity = enrolledPattern.patternCharacteristics.similarityScore(
                with: currentPattern.patternCharacteristics
            )
            
            let confidence = similarity / 100.0
            let threshold: Double = 0.75 // 75% similarity threshold
            
            let result: AuthenticationResult
            if confidence >= threshold {
                result = .approved(confidence: confidence)
                
                DispatchQueue.main.async {
                    // Update authentication service
                    self.authenticationService.isAuthenticated = true
                    self.authenticationService.lastAuthenticationResult = result
                }
                
                print("✅ Authentication successful: \(Int(similarity))% match")
            } else {
                result = .denied(reason: "Biometric pattern does not match (\(Int(similarity))% similarity)")
                print("❌ Authentication failed: \(Int(similarity))% match")
            }
            
            DispatchQueue.main.async {
                self.completeAuthentication(with: result)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.handleError("Authentication failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func createHeartPattern(from samples: [Double]) -> HeartPattern {
        let identifier = "Auth_\(UUID().uuidString.prefix(8))_\(Date().timeIntervalSince1970)"
        let encryptedId = identifier.data(using: .utf8)?.base64EncodedString() ?? identifier
        
        return HeartPattern(
            heartRateData: samples,
            duration: captureDuration,
            encryptedIdentifier: encryptedId
        )
    }
    
    private func completeAuthentication(with result: AuthenticationResult) {
        stopProcessingAnimation()
        authResult = result
        
        if result.isSuccessful {
            authenticationState = .completed
            WKInterfaceDevice.current().play(.success)
            
            // Auto-dismiss after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.dismiss()
            }
        } else {
            authenticationState = .failed
            retryCount += 1
            WKInterfaceDevice.current().play(.failure)
            
            // Show result sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showingResult = true
            }
        }
    }
    
    private func resetAuthentication() {
        authenticationState = .ready
        captureProgress = 0.0
        currentHeartRate = 0.0
        capturedSamples = []
        authResult = nil
        errorMessage = nil
    }
    
    private func handleCancel() {
        // Stop any ongoing capture
        if authenticationState == .capturing {
            healthKitService.stopHeartRateCapture()
        }
        
        stopProcessingAnimation()
        dismiss()
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showingError = true
        authenticationState = .failed
        retryCount += 1
        
        print("❌ Authentication error: \(message)")
    }
    
    private func startProcessingAnimation() {
        processingProgress = 0.0
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                self.processingProgress += 0.03
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

enum AuthenticationViewState: Equatable {
    case ready
    case capturing
    case processing
    case completed
    case failed
}

// MARK: - Authentication Result View

struct AuthenticationResultView: View {
    let result: AuthenticationResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Result Icon
                Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(result.isSuccessful ? .green : .red)
                
                // Result Title
                Text(result.isSuccessful ? "Authentication Successful" : "Authentication Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Result Message
                Text(result.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                Button(action: onDismiss) {
                    Text(result.isSuccessful ? "Continue" : "Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(result.isSuccessful ? Color.green : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}