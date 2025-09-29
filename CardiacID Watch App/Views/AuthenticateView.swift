import SwiftUI
import Foundation
import WatchKit

struct AuthenticateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var authenticationState: AuthenticationViewState = .ready
    @State private var captureProgress: Double = 0
    @State private var currentHeartRate: Double = 0
    @State private var retryCount = 0
    @State private var showingResult = false
    @State private var showingSuccess = false
    @State private var lastResult: AuthenticationResult?
    @State private var processingProgress: Double = 0
    @State private var processingTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var countdownValue = 3
    @State private var isInitializing = true
    
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
            case .initializing:
                InitializingStateView()
            case .countdown(let seconds):
                CountdownStateView(seconds: seconds)
            case .capturing:
                CapturingStateView(
                    progress: captureProgress,
                    heartRate: currentHeartRate
                )
            case .processing:
                ProcessingStateView(progress: processingProgress, title: "Processing Authentication")
            case .result(let result):
                ResultStateView(result: result, retryCount: retryCount)
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
            case .initializing, .countdown:
                EmptyView()
            case .capturing:
                capturingButtonsView
            case .processing:
                EmptyView()
            case .result(let result):
                resultButtonsView(result: result)
            }
        }
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
                    healthKitService.requestAuthorization()
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
                Text("• The process takes 9-16 seconds")
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
        
        // Stop all timers
        stopProcessingTimer()
        stopCountdownTimer()
        
        // Removed problematic WatchKit API call
        dismiss()
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
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
                authenticationState = .result(.failed)
            }
        }
        .alert("Authentication Result", isPresented: $showingResult) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let result = lastResult {
                Text(result.message)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("UserDeleted"))) { _ in
            // Dismiss the view when user is deleted
            dismiss()
        }
        .onAppear {
            // Set initializing state when view appears
            if isInitializing {
                authenticationState = .initializing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isInitializing = false
                    self.authenticationState = .ready
                }
            }
        }
        .onDisappear {
            // Clean up all timers and resources
            stopProcessingTimer()
            stopCountdownTimer()
            // Removed problematic WatchKit API call
        }
    }
    
    // MARK: - Actions
    
    private func startAuthentication() {
        // Validate system state before starting
        guard healthKitService.isAuthorized else {
            print("❌ HealthKit not authorized - cannot start authentication")
            return
        }
        
        // Ensure no other processes are running
        guard !healthKitService.isCapturing else {
            print("❌ Heart rate capture already in progress - waiting for completion")
            return
        }
        
        // Clean up any existing timers first
        stopProcessingTimer()
        stopCountdownTimer()
        
        retryCount = 0
        
        // Start with initialization phase
        authenticationState = .initializing
        
        // Give HealthKit and sensors time to initialize properly (increased delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("✅ HealthKit initialization complete - starting countdown")
            self.startCountdown()
        }
    }
    
    private func startCountdown() {
        // Validate state before starting countdown
        guard authenticationState == .initializing else {
            print("❌ Invalid state for countdown start: \(authenticationState)")
            return
        }
        
        countdownValue = 3
        authenticationState = .countdown(countdownValue)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                self.authenticationState = .countdown(self.countdownValue)
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                
                // Add delay before starting capture to ensure countdown fully completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("✅ Countdown complete - starting capture")
                    self.startCapture()
                }
            }
        }
    }
    
    private func startCapture() {
        // Validate state before starting capture
        guard authenticationState == .countdown(0) else {
            print("❌ Invalid state for capture start: \(authenticationState)")
            return
        }
        
        // Ensure HealthKit is ready
        guard healthKitService.isAuthorized && !healthKitService.isCapturing else {
            print("❌ HealthKit not ready for capture")
            return
        }
        
        authenticationState = .capturing
        
        // Start heart rate capture with proper duration
        let captureDuration: TimeInterval = 12.0 // Increased for better sensor engagement
        healthKitService.startHeartRateCapture(duration: captureDuration)
        
        print("📊 Starting heart rate capture for \(captureDuration) seconds")
        
        // Listen for completion with buffer time for sensor stabilization
        DispatchQueue.main.asyncAfter(deadline: .now() + captureDuration + 2.0) {
            if self.authenticationState == .capturing {
                print("✅ Capture duration complete - starting processing")
                self.completeAuthentication()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ Sensor capture closed - starting processing")
            self.completeAuthentication()
        }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.completeAuthentication()
            }
            return
        }
        
        print("🔬 Starting authentication processing...")
        authenticationState = .processing
        processingProgress = 0
        
        // Keep backlight on during processing (simplified for stability)
        // Removed problematic WatchKit API calls that can cause crashes
        
        // Start processing timer
        startProcessingTimer()
        
        // Get captured heart rate data with validation
        let heartRateData = healthKitService.heartRateSamples.map { $0.value }
        print("📊 Processing \(heartRateData.count) heart rate samples...")
        
        // Validate data quality
        guard heartRateData.count >= 5 else {
            print("❌ Insufficient heart rate samples: \(heartRateData.count)")
            stopProcessingTimer()
            authenticationState = .result(.failed)
            return
        }
        
        guard healthKitService.validateHeartRateData(healthKitService.heartRateSamples) else {
            print("❌ Heart rate data validation failed")
            stopProcessingTimer()
            authenticationState = .result(.failed)
            return
        }
        
        // Give Watch sensors and processing systems adequate time (increased for stability)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
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
            
            // Add buffer time before showing result to ensure processing is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.authenticationState = .result(result)
            }
        }
    }
    
    private func startProcessingTimer() {
        // Clean up any existing timer first
        stopProcessingTimer()
        
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.1)) {
                    processingProgress += 0.033 // Complete in 3 seconds (0.1 * 30 = 3.0)
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
        stopCountdownTimer()
        
        // Give system time to fully reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔄 Starting authentication retry")
            self.authenticationState = .ready
            self.startAuthentication()
        }
    }
    
    private func resetAuthentication() {
        // Clean up all resources
        stopProcessingTimer()
        stopCountdownTimer()
        
        // Ensure HealthKit is stopped
        if healthKitService.isCapturing {
            healthKitService.stopHeartRateCapture()
        }
        
        // Give system time to fully reset before changing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.authenticationState = .ready
            self.retryCount = 0
            self.lastResult = nil
            self.showingSuccess = false
            self.healthKitService.clearError()
            print("✅ Authentication system reset complete")
        }
    }
}

// MARK: - State Views

enum AuthenticationViewState: Equatable {
    case ready
    case initializing
    case countdown(Int)
    case capturing
    case processing
    case result(AuthenticationResult)
}

struct ResultStateView: View {
    let result: AuthenticationResult
    let retryCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Result Icon
            Image(systemName: resultIcon)
                .font(.system(size: 50))
                .foregroundColor(resultColor)
            
            // Result Text
            Text(resultTitle)
                .font(.headline)
                .foregroundColor(resultColor)
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Additional Info
            if result.requiresRetry && retryCount < 3 {
                Text("Please try again for better accuracy")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else if result == .systemUnavailable {
                Text("Please try again later")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var resultIcon: String {
        switch result {
        case .success, .approved:
            return "checkmark.circle.fill"
        case .retryRequired:
            return "exclamationmark.triangle.fill"
        case .failure, .failed:
            return "xmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .cancelled:
            return "xmark.circle"
        case .systemUnavailable:
            return "wifi.slash"
        }
    }
    
    private var resultColor: Color {
        switch result {
        case .success, .approved:
            return .green
        case .retryRequired:
            return .orange
        case .failure, .failed, .systemUnavailable:
            return .red
        case .pending:
            return .blue
        case .cancelled:
            return .gray
        }
    }
    
    private var resultTitle: String {
        switch result {
        case .success, .approved:
            return "Authentication Successful!"
        case .retryRequired:
            return "Please Try Again"
        case .failure, .failed:
            return "Authentication Failed"
        case .pending:
            return "Authentication Pending"
        case .cancelled:
            return "Authentication Cancelled"
        case .systemUnavailable:
            return "System Unavailable"
        }
    }
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

struct InitializingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing...")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Preparing heart rate sensor")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CountdownStateView: View {
    let seconds: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(seconds)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.orange)
            
            Text("Get Ready")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Place your finger on the Digital Crown")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct CapturingStateView: View {
    let progress: Double
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .scaleEffect(1.0 + (progress * 0.2))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: progress)
            
            Text("Capturing Heart Pattern")
                .font(.headline)
                .fontWeight(.bold)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
            
            Text("Heart Rate: \(Int(heartRate)) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


#Preview {
    AuthenticateView()
        .environmentObject(AuthenticationService())
        .environmentObject(HealthKitService())
}


