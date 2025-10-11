import SwiftUI
import Foundation
import WatchKit

struct AuthenticateView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var authenticationState: AuthenticationViewState = .ready
    @State private var captureProgress: Double = 0
    @State private var currentHeartRate: Double = 0
    @State private var retryCount = 0
    @State private var showingResult = false
    @State private var lastResult: AuthenticationResult?
    @State private var processingProgress: Double = 0
    @State private var processingTimer: Timer?
    
    private let maxRetries = 3
    
    // MARK: - Computed Views
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Authenticate")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Verify your identity using your heart pattern")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var statusDisplayView: some View {
        VStack(spacing: 16) {
            switch authenticationState {
            case .ready:
                ReadyStateView()
            case .capturing:
                CapturingStateView(
                    progress: captureProgress,
                    heartRate: currentHeartRate
                )
            case .processing:
                ProcessingStateView(progress: processingProgress, title: "Processing Authentication")
            case .result(let result):
                ResultStateView(result: result, retryCount: retryCount)
            case .error(let message):
                ErrorStateView(message: message)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            switch authenticationState {
            case .ready:
                readyButtonsView
            case .capturing:
                capturingButtonsView
            case .processing:
                EmptyView()
            case .result(let result):
                resultButtonsView(result: result)
            case .error:
                errorButtonsView
            }
        }
    }
    
    private var errorButtonsView: some View {
        Button("Try Again") {
            authenticationState = .ready
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var readyButtonsView: some View {
        VStack(spacing: 12) {
            Button("Start Authentication") {
                startAuthentication()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!healthKitService.isAuthorized)
            
            if !healthKitService.isAuthorized {
                Button("Authorize HealthKit") {
                    Task {
                        let result = await healthKitService.ensureAuthorization()
                        switch result {
                        case .authorized:
                            print("✅ HealthKit authorization successful")
                        case .denied(let message), .notAvailable(let message):
                            authenticationState = .error("HealthKit authorization failed: \(message)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var capturingButtonsView: some View {
        Button("Stop Capture") {
            stopCapture()
        }
        .buttonStyle(.bordered)
    }
    
    @ViewBuilder
    private func resultButtonsView(result: AuthenticationResult) -> some View {
        if result.requiresRetry && retryCount < maxRetries {
            Button("Try Again") {
                retryAuthentication()
            }
            .buttonStyle(.borderedProminent)
        } else if result.isSuccessful {
            Button("Continue") {
                NotificationCenter.default.post(name: .init("UserAuthenticated"), object: nil)
                showingResult = true
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button("Start Over") {
                resetAuthentication()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var instructionsView: some View {
        if authenticationState == .ready {
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions:")
                    .font(.headline)
                
                Text("• Place your finger on the Digital Crown")
                Text("• Keep your wrist stable")
                Text("• Remain still during capture")
                Text("• The process takes 6-8 seconds")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var retryInfoView: some View {
        if retryCount > 0 && retryCount < maxRetries {
            Text("Attempt \(retryCount) of \(maxRetries)")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                statusDisplayView
                actionButtonsView
                Spacer()
                instructionsView
                retryInfoView
            }
            .padding()
        }
    }
    
    private var cancelButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                cancelAuthentication()
            }
        }
    }
    
    private func cancelAuthentication() {
        // Clean up any ongoing processes
        if authenticationState == .capturing {
            healthKitService.stopHeartRateCapture()
        }
        
        // Stop processing timer
        stopProcessingTimer()
        
        // Reset to ready state instead of dismissing
        authenticationState = .ready
    }
    
    
    var body: some View {
        NavigationStack {
            mainContentView
                .navigationTitle("Authenticate")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    cancelButtonToolbar
                }
        }
        .onReceive(healthKitService.$captureProgress) { progress in
            // Ensure progress is finite and valid
            if progress.isFinite && !progress.isNaN {
                captureProgress = progress
            }
        }
        .onReceive(healthKitService.$currentHeartRate) { heartRate in
            currentHeartRate = heartRate
        }
        .onReceive(healthKitService.$errorMessage) { error in
            if let error = error, !error.isEmpty {
                print("HealthKit Error: \(error)")
                authenticationState = .result(.error(message: error))
            }
        }
        .alert("Authentication Result", isPresented: $showingResult) {
            Button("OK") {
                // Reset to ready state instead of dismissing
                authenticationState = .ready
            }
        } message: {
            if let result = lastResult {
                Text(result.message)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("UserDeleted"))) { _ in
            // Reset to ready state when user is deleted
            authenticationState = .ready
        }
        .onDisappear {
            // Clean up processing timer
            stopProcessingTimer()
        }
    }
    
    // MARK: - Actions
    
    private func startAuthentication() {
        print("🚀 Starting authentication process...")
        
        // First ensure HealthKit authorization
        Task {
            let authResult = await healthKitService.ensureAuthorization()
            
            switch authResult {
            case .authorized:
                // Validate sensor engagement
                let sensorResult = await healthKitService.validateSensorEngagement()
                
                switch sensorResult {
                case .ready:
                    // Validate system state before starting
                    guard !healthKitService.isCapturing else {
                        print("❌ Heart rate capture already in progress - waiting for completion")
                        return
                    }
                    
                    // Clean up any existing timers first
                    stopProcessingTimer()
                    
                    retryCount = 0
                    
                    // Start capture immediately - no countdown needed
                    startCapture()
                    
                case .notAuthorized(let message), .noRecentData(let message), .sensorError(let message):
                    authenticationState = .error("Sensor validation failed: \(message)")
                }
                
            case .denied(let message), .notAvailable(let message):
                authenticationState = .error("HealthKit authorization failed: \(message)")
            }
        }
    }
    
    
    private func startCapture() {
        // Ensure HealthKit is ready
        guard healthKitService.isAuthorized && !healthKitService.isCapturing else {
            print("❌ HealthKit not ready for capture")
            return
        }
        
        authenticationState = .capturing
        
        // Start heart rate capture with optimized duration
        let captureDuration: TimeInterval = 8.0 // Reduced from 12 seconds to 8 seconds
        healthKitService.startHeartRateCapture(duration: captureDuration) { samples, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Heart rate capture error: \(error)")
                    authenticationState = .error("Capture failed: \(error.localizedDescription)")
                } else {
                    print("✅ Heart rate capture completed with \(samples.count) samples")
                    // Process the captured samples for authentication
                    processAuthenticationSamples(samples)
                }
            }
        }
    }
    
    private func stopCapture() {
        // Ensure we're in capturing state before stopping
        guard authenticationState == .capturing else {
            print("❌ Not in capturing state - cannot stop capture")
            return
        }
        
        print("🛑 Stopping heart rate capture")
        healthKitService.stopHeartRateCapture()
        
        // Give sensors time to properly close out before processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("✅ Sensor capture closed - starting processing")
            self.completeAuthentication()
        }
    }
    
    private func processAuthenticationSamples(_ samples: [HeartRateSample]) {
        print("🔬 Processing \(samples.count) authentication samples")
        
        // Validate samples
        guard !samples.isEmpty else {
            authenticationState = .error("No heart rate data captured. Please try again.")
            return
        }
        
        guard samples.count >= 5 else {
            authenticationState = .error("Insufficient heart rate data (\(samples.count) samples). Need at least 5 samples.")
            return
        }
        
        // Validate data quality
        let values = samples.map { $0.value }
        let validValues = values.filter { $0 > 30 && $0 < 220 }
        guard validValues.count >= 5 else {
            authenticationState = .error("Invalid heart rate values detected. Please ensure proper sensor contact.")
            return
        }
        
        // Start authentication processing
        authenticationState = .processing
        processingProgress = 0
        startProcessingTimer()
        
        // Perform authentication with the captured data
        let result = authenticationService.completeAuthentication(with: values)
        
        // Stop processing timer and show result
        stopProcessingTimer()
        authenticationState = .result(result)
        
        print("✅ Authentication completed with result: \(result.isSuccess ? "Success" : "Failed")")
    }

    private func completeAuthentication() {
        // Validate state before processing
        guard authenticationState == .capturing else {
            print("❌ Invalid state for processing: \(authenticationState)")
            return
        }
        
        // Ensure HealthKit capture has fully stopped
        guard !healthKitService.isCapturing else {
            print("❌ HealthKit still capturing - waiting for completion")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.completeAuthentication()
            }
            return
        }
        
        print("🔬 Starting authentication processing...")
        authenticationState = .processing
        processingProgress = 0
        
        // Start processing timer
        startProcessingTimer()
        
        // Get captured heart rate data with validation
        let heartRateData = healthKitService.heartRateSamples.map { $0.value }
        print("📊 Processing \(heartRateData.count) heart rate samples...")
        
        // Validate data quality
        guard heartRateData.count >= 5 else {
            print("❌ Insufficient heart rate samples: \(heartRateData.count)")
            stopProcessingTimer()
            authenticationState = .result(.denied(reason: "Insufficient heart rate samples"))
            return
        }
        
        guard healthKitService.validateHeartRateData(heartRateData) else {
            print("❌ Heart rate data validation failed")
            stopProcessingTimer()
            authenticationState = .result(.denied(reason: "Heart rate data validation failed"))
            return
        }
        
        // Reduced processing time for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🔍 Performing authentication analysis...")
            
            // Perform authentication
            let result = self.authenticationService.completeAuthentication(with: heartRateData)
            self.lastResult = result
            
            print("✅ Authentication result: \(result.message)")
            
            // Update retry count if needed
            if result.requiresRetry {
                self.retryCount += 1
                print("🔄 Retry required - attempt \(self.retryCount)")
            }
            
            self.stopProcessingTimer()
            
            // Show result immediately
            self.authenticationState = .result(result)
        }
    }
    
    private func startProcessingTimer() {
        // Clean up any existing timer first
        stopProcessingTimer()
        
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.1)) {
                    processingProgress += 0.05 // Complete in 2 seconds (0.1 * 20 = 2.0)
                    if processingProgress >= 1.0 {
                        processingProgress = 1.0
                        stopProcessingTimer() // Stop timer when complete
                    }
                }
            }
        }
    }
    
    private func stopProcessingTimer() {
        processingTimer?.invalidate()
        processingTimer = nil
        processingProgress = 0
    }
    
    private func retryAuthentication() {
        // Ensure we're in a valid state for retry
        guard case .result = authenticationState else {
            print("❌ Invalid state for retry: \(authenticationState)")
            return
        }
        
        // Clean up all resources before retry
        stopProcessingTimer()
        
        // Give system time to fully reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔄 Starting authentication retry")
            self.authenticationState = .ready
            self.startAuthentication()
        }
    }
    
    private func resetAuthentication() {
        // Clean up all resources
        stopProcessingTimer()
        
        // Ensure HealthKit is stopped
        if healthKitService.isCapturing {
            healthKitService.stopHeartRateCapture()
        }
        
        // Give system time to fully reset before changing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.authenticationState = .ready
            self.retryCount = 0
            self.lastResult = nil
            self.healthKitService.clearError()
            print("✅ Authentication system reset complete")
        }
    }
}

// MARK: - State Views

enum AuthenticationViewState: Equatable {
    case ready
    case capturing
    case processing
    case result(AuthenticationResult)
    case error(String)
}


// MARK: - State Views

struct ReadyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Ready to Authenticate")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Place your finger on the Digital Crown and tap Start")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}


struct ErrorStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Authentication Error")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}




#Preview {
    AuthenticateView()
        .environmentObject(AuthenticationService())
        .environmentObject(HealthKitService())
}

// MARK: - Missing State Views

struct CapturingStateView: View {
    let progress: Double
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
            
            Text("Capturing...")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(Int(heartRate)) BPM")
                    .font(.body)
            }
            
            Text("Hold still, \(Int((1.0 - progress) * 8)) seconds remaining")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

