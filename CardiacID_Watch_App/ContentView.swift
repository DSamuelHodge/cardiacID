//
//  ContentView.swift
//  HeartID_WatchApp_V3 Watch App
//
//  Created by Jim Locke on 9/16/25.
//

import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var backgroundTaskService: BackgroundTaskService
    
    @State private var selectedTab = 0
    @State private var isUserEnrolled = false
    @State private var showEnrollmentFlow = false
    @State private var showLandingScreen = true
    @State private var landingTimer: Timer?
    
    var body: some View {
        Group {
            if showLandingScreen {
                // Show landing screen for 5 seconds
                LandingView()
            } else if !isUserEnrolled || showEnrollmentFlow {
                // Show enrollment flow if user is not enrolled
                EnrollmentFlowView(
                    isEnrolled: $isUserEnrolled,
                    showEnrollment: $showEnrollmentFlow,
                    onEnrollmentComplete: {
                        // Update local state
                        isUserEnrolled = true
                        showEnrollmentFlow = false
                        selectedTab = 1 // Go to menu screen
                        
                        // The authentication service should already be updated by the enrollment process
                        print("✅ Enrollment completed - User can now authenticate")
                    }
                )
            } else {
                TabView(selection: $selectedTab) {
                    // Landing Screen
                    LandingView()
                        .tag(0)
                    
                    // Menu Screen
                    MenuView()
                        .tag(1)
                    
                    // Enroll Screen
                    EnrollView()
                        .tag(2)
                    
                    // Authenticate Screen
                    AuthenticateView()
                        .tag(3)
                    
                    // Settings Screen
                    SettingsView()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .onAppear {
            // Set up the data manager in authentication service
            authenticationService.setDataManager(dataManager)
            // Check enrollment status
            checkEnrollmentStatus()
            // Start landing screen timer
            startLandingTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("UserDeleted"))) { _ in
            // Reset app state when user is deleted
            isUserEnrolled = false
            showEnrollmentFlow = true
            selectedTab = 0
            showLandingScreen = true
            startLandingTimer()
        }
        .onDisappear {
            // Clean up timer when view disappears
            landingTimer?.invalidate()
            landingTimer = nil
        }
    }
    
    private func startLandingTimer() {
        // Clear any existing timer
        landingTimer?.invalidate()
        
        // Start 5-second timer
        landingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.showLandingScreen = false
                print("⏰ Landing screen timer completed - transitioning to main app")
            }
        }
    }
    
    private func checkEnrollmentStatus() {
        // Check enrollment status from authentication service
        isUserEnrolled = authenticationService.isUserEnrolled
        
        if !isUserEnrolled {
            print("📝 User not enrolled - will show enrollment flow after landing screen")
            showEnrollmentFlow = true
        } else {
            print("✅ User already enrolled - will show menu after landing screen")
            showEnrollmentFlow = false
            selectedTab = 1 // Start with menu tab when enrolled
        }
    }
}

struct LandingView: View {
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 20) {
            // HeartID Logo/Icon
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5), value: showContent)
            
            Text("HeartID V0.3")
                .font(.system(size: 24))
                .fontWeight(.bold)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: showContent)
            
            Text("Biometric Authentication")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(0.4), value: showContent)
            
            Spacer()
            
            // Loading indicator
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Show content after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Enrollment Flow View
struct EnrollmentFlowView: View {
    @Binding var isEnrolled: Bool
    @Binding var showEnrollment: Bool
    let onEnrollmentComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var enrollmentProgress: Double = 0.0
    @State private var isCapturing = false
    @State private var captureProgress: Double = 0.0
    @State private var heartRateSamples: [Double] = []
    @State private var showSuccess = false
    
    private let totalSteps = 4
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress indicator
                VStack(spacing: 10) {
                    Text("Initial Enrollment")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    ProgressView(value: enrollmentProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                    
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        WelcomeStepView()
                    case 1:
                        InstructionsStepView()
                    case 2:
                        CaptureStepView(
                            isCapturing: $isCapturing,
                            captureProgress: $captureProgress,
                            heartRateSamples: $heartRateSamples
                        )
                    case 3:
                        CompletionStepView(
                            showSuccess: $showSuccess,
                            onComplete: completeEnrollment
                        )
                    default:
                        WelcomeStepView()
                    }
                }
                .padding()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                                updateProgress()
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button(currentStep == totalSteps - 1 ? "Complete" : "Next") {
                        if currentStep == totalSteps - 1 {
                            completeEnrollment()
                        } else if currentStep == 2 {
                            // Start capture when on capture step
                            isCapturing = true
                            startCaptureProcess()
                        } else {
                            withAnimation {
                                currentStep += 1
                                updateProgress()
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(currentStep == 2 && isCapturing) // Disable during capture
                }
                .padding()
            }
        }
        .onAppear {
            updateProgress()
        }
    }
    
    private func updateProgress() {
        let progress = Double(currentStep) / Double(totalSteps - 1)
        // Ensure progress is finite and valid
        if progress.isFinite && !progress.isNaN {
            enrollmentProgress = progress
        } else {
            enrollmentProgress = 0.0
        }
    }
    
    private func startCaptureProcess() {
        let startTime = Date()
        let captureDuration: TimeInterval = 30.0
        
        // Start the capture timer
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / captureDuration, 1.0)
            
            // Ensure progress is finite and valid
            if progress.isFinite && !progress.isNaN {
                captureProgress = progress
            }
            
            // Simulate heart rate data
            let simulatedHeartRate = Double.random(in: 60...120)
            heartRateSamples.append(simulatedHeartRate)
            
            if progress >= 1.0 {
                timer.invalidate()
                isCapturing = false
                captureProgress = 1.0 // Ensure it's exactly 1.0
                
                // Move to next step after capture completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        currentStep += 1
                        updateProgress()
                    }
                }
            }
        }
    }
    
    private func completeEnrollment() {
        // Show success animation
        withAnimation(.easeInOut(duration: 1.0)) {
            showSuccess = true
        }
        
        // Complete enrollment after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onEnrollmentComplete()
        }
    }
}

// MARK: - Enrollment Step Views
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "heart.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
            
            Text("Welcome to HeartID")
                .font(.system(size: 24))
                .fontWeight(.bold)
            
            Text("Let's set up your biometric authentication. This process will take just a few minutes.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
}

struct InstructionsStepView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("How it Works")
                .font(.system(size: 24))
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(icon: "1.circle.fill", text: "Place your finger on the heart rate sensor")
                InstructionRow(icon: "2.circle.fill", text: "Hold still for 30 seconds")
                InstructionRow(icon: "3.circle.fill", text: "We'll capture your unique heart pattern")
                InstructionRow(icon: "4.circle.fill", text: "Use this for secure authentication")
            }
        }
    }
}

struct CaptureStepView: View {
    @Binding var isCapturing: Bool
    @Binding var captureProgress: Double
    @Binding var heartRateSamples: [Double]
    
    @State private var timeRemaining = 30
    
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "heart.fill")
                .font(.system(size: 30))
                .foregroundColor(isCapturing ? .red : .gray)
                .scaleEffect(isCapturing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isCapturing)
            
            Text(isCapturing ? "Capturing Heart Pattern..." : "Ready to Capture")
                .font(.system(size: 24))
                .fontWeight(.bold)
            
            if isCapturing {
                VStack(spacing: 12) {
                    Text("\(timeRemaining) seconds remaining")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: captureProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                }
            } else {
                Text("Tap 'Next' to begin capturing your heart pattern")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if isCapturing {
                timeRemaining = 30
                captureProgress = 0.0
            }
        }
    }
}

struct CompletionStepView: View {
    @Binding var showSuccess: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: showSuccess ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 30))
                .foregroundColor(showSuccess ? .green : .orange)
                .scaleEffect(showSuccess ? 1.2 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
            
            Text(showSuccess ? "Enrollment Complete!" : "Processing...")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(showSuccess ? "Your heart pattern has been saved securely. You can now use HeartID for authentication." : "Please wait while we process your heart pattern data.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
