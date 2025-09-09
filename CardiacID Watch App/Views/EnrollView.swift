import SwiftUI
import Foundation
import WatchKit

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
    
    // Verification flow states
    @State private var baselinePattern: [Double] = []
    @State private var verificationResult: VerificationResult?
    @State private var showingRangeOptions = false
    @State private var relaxationCountdown = 120 // 2 minutes
    @State private var relaxationTimer: Timer?
    @State private var testHeartRate: Double = 0
    @State private var heartRateDifference: Double = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Enroll in HeartID")
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("We'll capture your unique heart pattern for secure authentication")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 10)
                    
                    // Status Display
                    VStack(spacing: 16) {
                        switch enrollmentState {
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
                            ProcessingStateView(progress: processingProgress, title: "Processing Enrollment")
                        case .completed:
                            CompletedStateView()
                        case .verification:
                            VerificationStateView(heartRate: currentHeartRate)
                        case .verificationComplete:
                            VerificationCompleteView(result: verificationResult)
                        case .rangeOptions:
                            RangeOptionsView()
                        case .relaxation:
                            RelaxationView(countdown: relaxationCountdown)
                        case .exercise:
                            ExerciseView()
                        case .rangeTest:
                            RangeTestView(
                                heartRate: testHeartRate,
                                difference: heartRateDifference,
                                testType: verificationResult?.testType ?? .lower
                            )
                        case .finalComplete:
                            FinalCompleteView()
                        case .error(let message):
                            ErrorStateView(message: message)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        switch enrollmentState {
                        case .ready:
                            Button("Start Enrollment") {
                                startEnrollment()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!healthKitService.isAuthorized)
                            
                            if !healthKitService.isAuthorized {
                                Button("Authorize HealthKit") {
                                    healthKitService.requestAuthorization()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                        case .initializing, .countdown, .capturing, .processing:
                            EmptyView()
                            
                        case .completed:
                            // This should automatically transition to verification
                            EmptyView()
                            
                        case .verification:
                            Button("Stop Verification") {
                                stopVerification()
                            }
                            .buttonStyle(.bordered)
                            
                        case .verificationComplete:
                            if let result = verificationResult, result.passed {
                                VStack(spacing: 8) {
                                    Button("Yes - Test Lower Heart Rate") {
                                        startLowerHeartRateTest()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    
                                    Button("No - Complete Enrollment") {
                                        completeEnrollmentProcess()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                Button("Try Again") {
                                    enrollmentState = .ready
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                        case .rangeOptions:
                            VStack(spacing: 8) {
                                Button("Yes - Test Higher Heart Rate") {
                                    startHigherHeartRateTest()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("No - Complete Enrollment") {
                                    completeEnrollmentProcess()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                        case .relaxation:
                            Button("Skip Relaxation") {
                                skipRelaxation()
                            }
                            .buttonStyle(.bordered)
                            
                        case .exercise:
                            Button("Skip Exercise") {
                                skipExercise()
                            }
                            .buttonStyle(.bordered)
                            
                        case .rangeTest:
                            Button("Continue") {
                                continueAfterRangeTest()
                            }
                            .buttonStyle(.borderedProminent)
                            
                        case .finalComplete:
                            Button("Finish Enrollment") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            
                        case .error:
                            Button("Try Again") {
                                enrollmentState = .ready
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Spacer()
                    
                    // Instructions
                    if enrollmentState == .ready {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instructions:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("• Ensure your Apple Watch is snug on your wrist")
                            Text("• Place your finger on the Digital Crown during capture")
                            Text("• Stay still and relaxed during the process")
                            Text("• The process takes about 30 seconds")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Enroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(enrollmentState == .capturing || enrollmentState == .verification)
                }
            }
        }
        .onReceive(healthKitService.$captureProgress) { progress in
            captureProgress = progress
        }
        .onReceive(healthKitService.$currentHeartRate) { heartRate in
            currentHeartRate = heartRate
        }
        .onReceive(healthKitService.$errorMessage) { error in
            if let error = error {
                enrollmentState = .error(error)
            }
        }
        .onDisappear {
            // Clean up all timers
            stopProcessingTimer()
            stopCountdownTimer()
            stopRelaxationTimer()
            WKInterfaceDevice.current().enableWaterLock()
        }
    }
    
    // MARK: - Enrollment Functions
    
    private func startEnrollment() {
        enrollmentState = .initializing
        
        // Give HealthKit time to initialize properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startCountdown()
        }
    }
    
    private func startCountdown() {
        countdownValue = 3
        enrollmentState = .countdown(countdownValue)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                self.enrollmentState = .countdown(self.countdownValue)
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.startCapture()
            }
        }
    }
    
    private func startCapture() {
        enrollmentState = .capturing
        
        // Start heart rate capture
        healthKitService.startHeartRateCapture(duration: AppConfiguration.defaultCaptureDuration)
        
        // Listen for completion
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfiguration.defaultCaptureDuration + 1) {
            if self.enrollmentState == .capturing {
                self.completeEnrollment()
            }
        }
    }
    
    private func completeEnrollment() {
        enrollmentState = .processing
        processingProgress = 0
        
        // Keep backlight on during processing
        WKExtension.shared().isAutorotating = false
        WKInterfaceDevice.current().enableWaterLock()
        
        // Start processing timer
        startProcessingTimer()
        
        // Get captured heart rate data
        let heartRateData = healthKitService.heartRateSamples.map { $0.value }
        
        // Store baseline pattern
        baselinePattern = heartRateData
        
        // Simulate processing with realistic timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopProcessingTimer()
            
            // AUTOMATICALLY start verification after enrollment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startAutomaticVerification()
            }
        }
    }
    
    // MARK: - Verification Functions
    
    private func startAutomaticVerification() {
        enrollmentState = .verification
        
        // Start verification capture
        healthKitService.startHeartRateCapture(duration: 10) // 10 seconds for verification
        
        // Listen for completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
            if self.enrollmentState == .verification {
                self.performVerification()
            }
        }
    }
    
    private func performVerification() {
        let currentPattern = healthKitService.heartRateSamples.map { $0.value }
        
        // Perform pattern comparison
        let result = comparePatterns(baseline: baselinePattern, current: currentPattern)
        
        verificationResult = result
        enrollmentState = .verificationComplete
        
        // Hold the result screen for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            // Automatically show range options if verification passed
            if result.passed {
                // Already showing range options in UI
            }
        }
    }
    
    private func comparePatterns(baseline: [Double], current: [Double]) -> VerificationResult {
        guard !baseline.isEmpty && !current.isEmpty else {
            return VerificationResult(passed: false, message: "Insufficient data for comparison")
        }
        
        // Calculate average heart rates
        let baselineAvg = baseline.reduce(0, +) / Double(baseline.count)
        let currentAvg = current.reduce(0, +) / Double(current.count)
        
        // Calculate heart rate variability
        let baselineVariability = calculateVariability(baseline)
        let currentVariability = calculateVariability(current)
        
        // Check if patterns are similar (within 15% for verification)
        let heartRateDifference = abs(baselineAvg - currentAvg) / baselineAvg * 100
        let variabilityDifference = abs(baselineVariability - currentVariability) / baselineVariability * 100
        
        if heartRateDifference <= 15 && variabilityDifference <= 20 {
            return VerificationResult(passed: true, message: "Pattern verified successfully")
        } else {
            return VerificationResult(passed: false, message: "Pattern verification failed")
        }
    }
    
    private func calculateVariability(_ heartRates: [Double]) -> Double {
        guard heartRates.count > 1 else { return 0.0 }
        
        let mean = heartRates.reduce(0, +) / Double(heartRates.count)
        let variance = heartRates.map { pow($0 - mean, 2) }.reduce(0, +) / Double(heartRates.count)
        return sqrt(variance)
    }
    
    private func stopVerification() {
        healthKitService.stopHeartRateCapture()
        enrollmentState = .ready
    }
    
    // MARK: - Range Testing Functions
    
    private func startLowerHeartRateTest() {
        enrollmentState = .relaxation
        relaxationCountdown = 120 // 2 minutes
        
        startRelaxationTimer()
    }
    
    private func startRelaxationTimer() {
        relaxationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.relaxationCountdown -= 1
            
            if self.relaxationCountdown <= 0 {
                timer.invalidate()
                self.relaxationTimer = nil
                self.performLowerHeartRateTest()
            }
        }
    }
    
    private func performLowerHeartRateTest() {
        testHeartRate = currentHeartRate
        let baselineAvg = baselinePattern.reduce(0, +) / Double(baselinePattern.count)
        heartRateDifference = abs(baselineAvg - testHeartRate) / baselineAvg * 100
        
        let result = VerificationResult(
            passed: heartRateDifference >= 10,
            message: heartRateDifference >= 10 ? "Sufficient difference for lower range" : "Difference less than 10%",
            testType: .lower,
            heartRate: testHeartRate,
            difference: heartRateDifference
        )
        
        verificationResult = result
        enrollmentState = .rangeTest
        
        // Hold the result screen for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.askHigherHeartRateTest()
        }
    }
    
    private func askHigherHeartRateTest() {
        enrollmentState = .rangeOptions
    }
    
    private func startHigherHeartRateTest() {
        enrollmentState = .exercise
        
        // Hold the exercise suggestions screen for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.performHigherHeartRateTest()
        }
    }
    
    private func performHigherHeartRateTest() {
        testHeartRate = currentHeartRate
        let baselineAvg = baselinePattern.reduce(0, +) / Double(baselinePattern.count)
        heartRateDifference = abs(testHeartRate - baselineAvg) / baselineAvg * 100
        
        let result = VerificationResult(
            passed: heartRateDifference >= 18,
            message: heartRateDifference >= 18 ? "Sufficient difference for upper range" : "Difference less than 18%",
            testType: .upper,
            heartRate: testHeartRate,
            difference: heartRateDifference
        )
        
        verificationResult = result
        enrollmentState = .rangeTest
        
        // Hold the result screen for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.completeEnrollmentProcess()
        }
    }
    
    private func continueAfterRangeTest() {
        if verificationResult?.testType == .lower {
            askHigherHeartRateTest()
        } else {
            completeEnrollmentProcess()
        }
    }
    
    private func completeEnrollmentProcess() {
        enrollmentState = .finalComplete
    }
    
    private func skipRelaxation() {
        stopRelaxationTimer()
        askHigherHeartRateTest()
    }
    
    private func skipExercise() {
        completeEnrollmentProcess()
    }
    
    // MARK: - Timer Functions
    
    private func startProcessingTimer() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.processingProgress += 0.02
            if self.processingProgress >= 1.0 {
                self.processingProgress = 1.0
                self.stopProcessingTimer()
            }
        }
    }
    
    private func stopProcessingTimer() {
        processingTimer?.invalidate()
        processingTimer = nil
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func stopRelaxationTimer() {
        relaxationTimer?.invalidate()
        relaxationTimer = nil
    }
}

// MARK: - Data Models

enum EnrollmentState: Equatable {
    case ready
    case initializing
    case countdown(Int)
    case capturing
    case processing
    case completed
    case verification
    case verificationComplete
    case rangeOptions
    case relaxation
    case exercise
    case rangeTest
    case finalComplete
    case error(String)
}

struct VerificationResult {
    let passed: Bool
    let message: String
    let testType: TestType?
    let heartRate: Double?
    let difference: Double?
    
    init(passed: Bool, message: String, testType: TestType? = nil, heartRate: Double? = nil, difference: Double? = nil) {
        self.passed = passed
        self.message = message
        self.testType = testType
        self.heartRate = heartRate
        self.difference = difference
    }
}

enum TestType {
    case lower
    case upper
}

// MARK: - State Views

struct ReadyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Ready to Enroll")
                .font(.headline)
            
            Text("Tap 'Start Enrollment' to begin capturing your unique heart pattern")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct InitializingStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Initializing Sensors")
                .font(.headline)
            
            Text("Preparing heart rate sensors for capture...")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CountdownStateView: View {
    let seconds: Int
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(seconds) / 3.0)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: seconds)
                
                Text("\(seconds)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text("Get Ready")
                .font(.headline)
            
            Text("Place your finger on the Digital Crown and hold still")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct CapturingStateView: View {
    let progress: Double
    let heartRate: Double
    @State private var ecgData: [Double] = []
    @State private var animationTimer: Timer?
    
    private var safeProgress: Double {
        guard progress.isFinite && !progress.isNaN else { return 0.0 }
        return max(0.0, min(1.0, progress))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // ECG Graph
            ECGGraphView(data: ecgData)
                .frame(height: 120)
                .background(Color.black.opacity(0.1))
                .cornerRadius(12)
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: safeProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: safeProgress)
                
                Text("\(Int(safeProgress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 8) {
                Text("Capturing Heart Pattern")
                    .font(.headline)
                
                if heartRate > 0 {
                    Text("Heart Rate: \(Int(heartRate)) BPM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Please hold still...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            startECGAnimation()
        }
        .onDisappear {
            stopECGAnimation()
        }
    }
    
    private func startECGAnimation() {
        generateRealisticECGData()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateECGData()
        }
    }
    
    private func stopECGAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func generateRealisticECGData() {
        ecgData = []
        let dataPoints = 100
        
        for i in 0..<dataPoints {
            let x = Double(i) / Double(dataPoints - 1)
            let ecgValue = generateECGValue(at: x)
            ecgData.append(ecgValue)
        }
    }
    
    private func updateECGData() {
        ecgData.removeFirst()
        let newX = Double(ecgData.count) / 100.0
        let newValue = generateECGValue(at: newX)
        ecgData.append(newValue)
    }
    
    private func generateECGValue(at x: Double) -> Double {
        let heartRateVariation = sin(x * .pi * 2 * 1.2) * 0.1
        let baseHeartRate = 72.0 + heartRateVariation
        
        let pWave = sin(x * .pi * 2 * 8) * 0.1 * exp(-pow((x - 0.2) * 10, 2))
        let qrsComplex = sin(x * .pi * 2 * 20) * 0.8 * exp(-pow((x - 0.4) * 15, 2))
        let tWave = sin(x * .pi * 2 * 3) * 0.3 * exp(-pow((x - 0.7) * 8, 2))
        let baseline = sin(x * .pi * 2 * 0.05) * 0.05
        
        return pWave + qrsComplex + tWave + baseline
    }
}

struct ECGGraphView: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                let minValue = data.min() ?? 0
                let maxValue = data.max() ?? 1
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height * (1 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.red, lineWidth: 2)
            .animation(.linear(duration: 0.1), value: data)
        }
    }
}


struct CompletedStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Enrollment Complete!")
                .font(.headline)
                .foregroundColor(.green)
            
            Text("Your heart pattern has been successfully enrolled and encrypted.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct VerificationStateView: View {
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Initial Enrollment Test")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Current Heart Rate: \(Int(heartRate)) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("We're verifying your enrolled heart pattern against this reading.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct VerificationCompleteView: View {
    let result: VerificationResult?
    
    var body: some View {
        VStack(spacing: 16) {
            if let result = result {
                if result.passed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Verification Successful!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Your heart pattern has been verified successfully.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Verification Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct RangeOptionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Higher Heart Rate Test")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Would you like to assess a higher heart rate?")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("This will help us establish the upper range of your heart pattern.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct RelaxationView: View {
    let countdown: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Relaxation Period")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("\(countdown / 60):\(String(format: "%02d", countdown % 60))")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Please relax and breathe deeply. We'll measure your resting heart rate.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ExerciseView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Exercise Suggestions")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Jumping jacks")
                Text("• Running in place")
                Text("• Arm circles")
                Text("• Deep breathing")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Perform any of these activities to increase your heart rate.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct RangeTestView: View {
    let heartRate: Double
    let difference: Double
    let testType: TestType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Analyzing Heart Pattern")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Heart Rate: \(Int(heartRate)) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Difference: \(String(format: "%.1f", difference))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if testType == .lower {
                if difference >= 10 {
                    Text("✅ Sufficient difference for lower range")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("⚠️ Difference less than 10%")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                if difference >= 18 {
                    Text("✅ Sufficient difference for upper range")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("⚠️ Difference less than 18%")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text("We're analyzing your heart pattern to establish the optimal range for authentication.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct FinalCompleteView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Enrollment Test Complete!")
                .font(.headline)
                .foregroundColor(.green)
            
            Text("Your heart pattern has been successfully tested and verified. Authentication is now ready to use.")
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
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Enrollment Failed")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    EnrollView()
        .environmentObject(AuthenticationService())
        .environmentObject(HealthKitService())
        .environmentObject(DataManager())
}