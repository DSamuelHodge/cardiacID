//
//  ContentView.swift
//  HeartID Watch App
//
//  Main content view for the HeartID Watch App
//

import SwiftUI
import Foundation
import Combine
import HealthKit
import Security

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
                // Show landing screen briefly
                LandingView()
            } else if !isUserEnrolled {
                // Show enrollment flow if user is not enrolled
                EnrollmentFlowView(
                    isEnrolled: $isUserEnrolled,
                    showEnrollment: $showEnrollmentFlow,
                    onEnrollmentComplete: {
                        // Update local state
                        isUserEnrolled = true
                        showEnrollmentFlow = false
                        selectedTab = 1 // Go to menu screen
                        
                        print("✅ Enrollment completed - User can now authenticate")
                    }
                )
            } else {
                // Show main app tabs for enrolled users
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
            authenticationService.dataManager = dataManager
            // Check enrollment status
            checkEnrollmentStatus()
            // Start landing screen timer
            startLandingTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("UserDeleted"))) { _ in
            // Reset app state when user is deleted
            isUserEnrolled = false
            showEnrollmentFlow = false
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
        
        // Reduced to 0.5 seconds - minimal branding display
        landingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async {
                // Ensure enrollment status is set before hiding landing screen
                self.checkEnrollmentStatus()
                self.showLandingScreen = false
                print("⏰ Landing screen timer completed - transitioning to main app")
            }
        }
    }
    
    private func checkEnrollmentStatus() {
        // Check enrollment status from DataManager
        isUserEnrolled = dataManager.isUserEnrolled
        
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
            
            Text("HeartID V0.4")
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
                    .scaleEffect(0.8)
                
                Text("Initializing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            showContent = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(HealthKitService())
        .environmentObject(DataManager.shared)
        .environmentObject(BackgroundTaskService())
}