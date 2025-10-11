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
                                // Start HealthKit authorization
                                Task {
                                    let success = await healthKitService.requestAuthorization()
                                    if success {
                                        currentStep += 1
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
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(isCapturing ? .red : .gray)
                .scaleEffect(isCapturing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isCapturing)
            
            Text(isCapturing ? "Capturing..." : "Ready to Capture")
                .font(.title2)
                .fontWeight(.bold)
            
            if isCapturing {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap 'Next' to start capturing your heart pattern")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCapturing {
                VStack(spacing: 8) {
                    Button("Start Capture") {
                        startCapture()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Debug info
                    Text("HealthKit: \(healthKitService.isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !healthKitService.isAuthorized {
                        Button("Authorize HealthKit") {
                            Task {
                                let success = await healthKitService.requestAuthorization()
                                print("Authorization result: \(success)")
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // Check HealthKit authorization status when view appears
            healthKitService.checkAuthorizationStatus()
        }
        .onDisappear {
            stopCapture()
        }
    }
    
    private func startCapture() {
        print("🚀 Starting capture in EnrollmentFlowView...")
        
        // Check HealthKit authorization first
        guard healthKitService.isAuthorized else {
            print("❌ HealthKit not authorized - requesting authorization")
            Task {
                let success = await healthKitService.requestAuthorization()
                if success {
                    print("✅ HealthKit authorization granted - retrying capture")
                    startCapture() // Retry after authorization
                } else {
                    print("❌ HealthKit authorization failed")
                    DispatchQueue.main.async {
                        isCapturing = false
                    }
                }
            }
            return
        }
        
        print("✅ HealthKit authorized - starting capture")
        isCapturing = true
        startTime = Date()
        capturedSamples = []
        
        // Start heart rate capture
        healthKitService.startHeartRateCapture(duration: 30.0) { samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Capture error: \(error.localizedDescription)")
                    isCapturing = false
                } else {
                    print("✅ Capture completed with \(samples.count) samples")
                    capturedSamples = samples.map { $0.value }
                    onCaptureComplete(samples.map { $0.value })
                }
            }
        }
        
        // Start progress timer
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateProgress()
        }
    }
    
    private func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        isCapturing = false
    }
    
    private func updateProgress() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalDuration: TimeInterval = 30.0
        progress = min(elapsed / totalDuration, 1.0)
        
        if progress >= 1.0 {
            stopCapture()
        }
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
