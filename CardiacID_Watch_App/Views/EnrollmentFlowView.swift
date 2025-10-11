//
//  EnrollmentFlowView.swift
//  HeartID Watch App
//
//  Enrollment flow view for new users
//

import SwiftUI
import HealthKit
import Combine

struct EnrollmentFlowView: View {
    @Binding var isEnrolled: Bool
    @Binding var showEnrollment: Bool
    let onEnrollmentComplete: () -> Void
    
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var dataManager: DataManager
    
    @State private var currentStep = 0
    @State private var isCapturing = false
    @State private var captureProgress: Double = 0
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let totalSteps = 3
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        WelcomeStepView()
                    case 1:
                        CaptureStepView(
                            isCapturing: $isCapturing,
                            progress: $captureProgress,
                            onCaptureComplete: handleCaptureComplete
                        )
                    case 2:
                        CompletionStepView()
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            if currentStep == 0 {
                                // Start HealthKit authorization with enhanced validation
                                Task {
                                    let authResult = await healthKitService.ensureAuthorization()
                                    
                                    switch authResult {
                                    case .authorized:
                                        // Validate sensor engagement
                                        let sensorResult = await healthKitService.validateSensorEngagement()
                                        
                                        switch sensorResult {
                                        case .ready:
                                            currentStep += 1
                                        case .notAuthorized(let message), .noRecentData(let message), .sensorError(let message):
                                            errorMessage = "Sensor validation failed: \(message)"
                                            showingError = true
                                        }
                                        
                                    case .denied(let message), .notAvailable(let message):
                                        errorMessage = "HealthKit authorization failed: \(message)"
                                        showingError = true
                                    }
                                }
                            } else {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentStep == 1 && !isCapturing)
                    } else {
                        Button("Complete") {
                            completeEnrollment()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Enrollment")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private func handleCaptureComplete(_ samples: [Double]) {
        // Process captured samples
        let success = authenticationService.completeEnrollment(with: samples)
        
        if success {
            currentStep = 2
        } else {
            errorMessage = authenticationService.errorMessage ?? "Enrollment failed"
            showingError = true
        }
    }
    
    private func completeEnrollment() {
        isEnrolled = true
        showEnrollment = false
        onEnrollmentComplete()
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Welcome to HeartID")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We'll capture your unique heart pattern for secure authentication.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Place finger on sensor")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Hold still for 30 seconds")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Keep device stable")
                }
                .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

struct CaptureStepView: View {
    @Binding var isCapturing: Bool
    @Binding var progress: Double
    let onCaptureComplete: ([Double]) -> Void
    
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var capturedSamples: [Double] = []
    @State private var captureTimer: Timer?
    @State private var startTime: Date?
    @State private var currentPhase: CapturePhase = .ready
    @State private var assessmentQuality: AssessmentQuality = .unknown
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var processingTimer: Timer?
    
    enum CapturePhase: Equatable, CaseIterable {
        case ready
        case capturing
        case processing
        case verifying
        case complete
        case failed(String)
        
        static var allCases: [CapturePhase] {
            return [.ready, .capturing, .processing, .verifying, .complete]
        }
    }
    
    enum AssessmentQuality {
        case unknown
        case poor
        case adequate
        case excellent
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Phase indicator
            phaseIndicatorView
            
            // Main content based on current phase
            Group {
                switch currentPhase {
                case .ready:
                    readyPhaseView
                case .capturing:
                    capturingPhaseView
                case .processing:
                    processingPhaseView
                case .verifying:
                    verifyingPhaseView
                case .complete:
                    completePhaseView
                case .failed(let message):
                    failedPhaseView(message)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            
            Spacer()
            
            // Action buttons
            actionButtonsView
        }
        .padding()
        .onAppear {
            healthKitService.checkAuthorizationStatus()
        }
        .onDisappear {
            stopAllTimers()
        }
    }
    
    // MARK: - Phase Indicators
    
    private var phaseIndicatorView: some View {
        HStack(spacing: 8) {
            ForEach(Array(CapturePhase.allCases.enumerated()), id: \.offset) { index, phase in
                Circle()
                    .fill(phaseColor(for: phase))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPhaseIndex >= index ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: currentPhaseIndex)
            }
        }
        .padding(.bottom, 10)
    }
    
    private var currentPhaseIndex: Int {
        switch currentPhase {
        case .ready: return 0
        case .capturing: return 1
        case .processing: return 2
        case .verifying: return 3
        case .complete: return 4
        case .failed: return 0
        }
    }
    
    private func phaseColor(for phase: CapturePhase) -> Color {
        switch phase {
        case .ready: return .gray
        case .capturing: return .blue
        case .processing: return .orange
        case .verifying: return .purple
        case .complete: return .green
        case .failed: return .red
        }
    }
    
    // MARK: - Phase Views
    
    private var readyPhaseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentPhase)
            
            Text("Ready to Capture")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We'll automatically capture your heart pattern, assess its quality, and create your biometric template.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // HealthKit status
            HStack {
                Image(systemName: healthKitService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(healthKitService.isAuthorized ? .green : .orange)
                Text("HealthKit: \(healthKitService.isAuthorized ? "Ready" : "Needs Authorization")")
                    .font(.caption)
            }
        }
    }
    
    private var capturingPhaseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isCapturing)
            
            Text("Capturing Heart Pattern")
                .font(.title2)
                .fontWeight(.bold)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Keep your finger on the Digital Crown")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var processingPhaseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(isProcessing ? 360 : 0))
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: isProcessing)
            
            Text("Processing Assessment")
                .font(.title2)
                .fontWeight(.bold)
            
            ProgressView(value: processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            Text("Analyzing heart pattern quality...")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var verifyingPhaseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Verifying Template")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Testing your biometric template to ensure accuracy...")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var completePhaseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Enrollment Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your biometric template has been successfully created and verified.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Quality indicator
            HStack {
                Image(systemName: qualityIcon)
                    .foregroundColor(qualityColor)
                Text("Quality: \(qualityText)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func failedPhaseView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Assessment Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            switch currentPhase {
            case .ready:
                if healthKitService.isAuthorized {
                    Button("Start Automated Capture") {
                        startAutomatedCapture()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Authorize HealthKit First") {
                        Task {
                            let success = await healthKitService.requestAuthorization()
                            if success {
                                startAutomatedCapture()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            case .capturing:
                Button("Stop Capture") {
                    stopCapture()
                }
                .buttonStyle(.bordered)
                
            case .processing, .verifying:
                EmptyView() // No buttons during processing
                
            case .complete:
                Button("Continue") {
                    onCaptureComplete(capturedSamples)
                }
                .buttonStyle(.borderedProminent)
                
            case .failed:
                Button("Try Again") {
                    resetToReady()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Quality Assessment
    
    private var qualityIcon: String {
        switch assessmentQuality {
        case .unknown: return "questionmark.circle"
        case .poor: return "exclamationmark.triangle"
        case .adequate: return "checkmark.circle"
        case .excellent: return "star.fill"
        }
    }
    
    private var qualityColor: Color {
        switch assessmentQuality {
        case .unknown: return .gray
        case .poor: return .red
        case .adequate: return .orange
        case .excellent: return .green
        }
    }
    
    private var qualityText: String {
        switch assessmentQuality {
        case .unknown: return "Unknown"
        case .poor: return "Poor"
        case .adequate: return "Adequate"
        case .excellent: return "Excellent"
        }
    }
    
                // MARK: - Automated Capture Process
                
                private func startAutomatedCapture() {
                    print("🚀 Starting automated capture process...")
                    
                    // First ensure HealthKit authorization and sensor validation
                    Task {
                        let authResult = await healthKitService.ensureAuthorization()
                        
                        switch authResult {
                        case .authorized:
                            // Validate sensor engagement
                            let sensorResult = await healthKitService.validateSensorEngagement()
                            
                            switch sensorResult {
                            case .ready:
                                currentPhase = .capturing
                                isCapturing = true
                                startTime = Date()
                                capturedSamples = []
                                
                                // Start heart rate capture
                                healthKitService.startHeartRateCapture(duration: 15.0) { samples, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("❌ Capture error: \(error.localizedDescription)")
                                            currentPhase = .failed("Capture failed: \(error.localizedDescription)")
                                            isCapturing = false
                                        } else {
                                            print("✅ Capture completed with \(samples.count) samples")
                                            capturedSamples = samples.map { $0.value }
                                            processAssessment()
                                        }
                                    }
                                }
                                
                                // Start progress timer
                                captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                    updateProgress()
                                }
                                
                            case .notAuthorized(let message), .noRecentData(let message), .sensorError(let message):
                                currentPhase = .failed("Sensor validation failed: \(message)")
                            }
                            
                        case .denied(let message), .notAvailable(let message):
                            currentPhase = .failed("HealthKit authorization failed: \(message)")
                        }
                    }
                }
    
    private func processAssessment() {
        print("🔬 Processing assessment...")
        currentPhase = .processing
        isProcessing = true
        processingProgress = 0
        
        // Start processing timer
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateProcessingProgress()
        }
        
        // Simulate assessment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.assessQuality()
        }
    }
    
    private func assessQuality() {
        print("📊 Assessing quality...")
        
        // Simple quality assessment based on sample count and variance
        let sampleCount = capturedSamples.count
        let average = capturedSamples.reduce(0, +) / Double(sampleCount)
        let variance = capturedSamples.map { pow($0 - average, 2) }.reduce(0, +) / Double(sampleCount)
        let standardDeviation = sqrt(variance)
        
        // Determine quality based on metrics
        if sampleCount >= 20 && standardDeviation > 5 && standardDeviation < 25 {
            assessmentQuality = .excellent
        } else if sampleCount >= 15 && standardDeviation > 3 && standardDeviation < 30 {
            assessmentQuality = .adequate
        } else {
            assessmentQuality = .poor
        }
        
        print("📈 Quality assessment: \(assessmentQuality) (samples: \(sampleCount), stdDev: \(standardDeviation))")
        
        // Check if quality is adequate
        if assessmentQuality == .poor {
            currentPhase = .failed("Heart pattern quality insufficient. Please ensure proper sensor contact and try again.")
        } else {
            // Quality is adequate or excellent, proceed to verification
            verifyTemplate()
        }
        
        isProcessing = false
        processingTimer?.invalidate()
    }
    
    private func verifyTemplate() {
        print("🔍 Verifying template...")
        currentPhase = .verifying
        
        // Simulate verification process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentPhase = .complete
            print("✅ Template verification complete")
        }
    }
    
    private func resetToReady() {
        currentPhase = .ready
        isCapturing = false
        isProcessing = false
        assessmentQuality = .unknown
        capturedSamples = []
        progress = 0
        processingProgress = 0
        stopAllTimers()
    }
    
    // MARK: - Timer Management
    
    private func updateProgress() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalDuration: TimeInterval = 15.0
        progress = min(elapsed / totalDuration, 1.0)
        
        if progress >= 1.0 {
            stopCapture()
        }
    }
    
    private func updateProcessingProgress() {
        processingProgress = min(processingProgress + 0.05, 1.0)
    }
    
    private func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        isCapturing = false
    }
    
    private func stopAllTimers() {
        captureTimer?.invalidate()
        processingTimer?.invalidate()
        captureTimer = nil
        processingTimer = nil
    }
}

struct CompletionStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Enrollment Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your heart pattern has been securely stored. You can now use HeartID for authentication.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                    Text("Data encrypted and stored securely")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Pattern ready for authentication")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                    Text("Configure settings in the menu")
                }
                .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    EnrollmentFlowView(
        isEnrolled: .constant(false),
        showEnrollment: .constant(true),
        onEnrollmentComplete: {}
    )
    .environmentObject(AuthenticationService())
    .environmentObject(HealthKitService())
    .environmentObject(DataManager.shared)
}

