//
//  HeartIDWatchApp.swift
//  HeartID Watch App
//
//  Enterprise-ready main app entry point
//

import SwiftUI
import HealthKit

@main
struct HeartID_WatchApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .onAppear {
                    // Initialize app state asynchronously with fallback timeout
                    Task {
                        await appState.initialize()
                    }
                    
                    // Fallback: Force initialization after 5 seconds if still loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if !appState.isInitialized {
                            print("⚠️ Forcing initialization due to timeout")
                            appState.isInitialized = true
                        }
                    }
                }
        }
    }
}

// MARK: - App State Management

@MainActor
class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isUserEnrolled = false
    @Published var healthKitAvailable = false
    @Published var errorMessage: String?
    
    // Core services
    let dataManager = DataManager.shared
    let authenticationService = AuthenticationService()
    let healthKitService = HealthKitService()
    
    func initialize() async {
        print("🚀 Starting app initialization...")
        
        // Check enrollment status first (fast operation)
        isUserEnrolled = dataManager.isUserEnrolled
        print("📊 User enrolled: \(isUserEnrolled)")
        
        // Check HealthKit availability (non-blocking)
        healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("🏥 HealthKit available: \(healthKitAvailable)")
        
        // Request HealthKit authorization asynchronously if needed (non-blocking)
        if healthKitAvailable && !isUserEnrolled {
            print("🔐 Requesting HealthKit authorization...")
            Task {
                await requestHealthKitAuthorization()
            }
        }
        
        print("✅ App initialization complete")
        isInitialized = true
    }
    
    private func requestHealthKitAuthorization() async {
        print("🔐 Starting HealthKit authorization...")
        
        // Use the existing HealthKitService instead of creating a new HKHealthStore
        // Add timeout to prevent hanging
        let success = await withTimeout(seconds: 10) {
            await healthKitService.requestAuthorization()
        }
        
        if !success {
            print("⚠️ HealthKit authorization failed or timed out")
            errorMessage = "HealthKit authorization failed"
        } else {
            print("✅ HealthKit authorization successful")
        }
    }
    
    // Helper function for timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isInitialized {
                // Show loading screen while initializing
                LoadingView()
            } else if let error = appState.errorMessage {
                // Show error state
                ErrorView(message: error)
            } else if !appState.isUserEnrolled {
                // Show enrollment flow
                EnrollmentFlowView(
                    isEnrolled: $appState.isUserEnrolled,
                    showEnrollment: .constant(true),
                    onEnrollmentComplete: {
                        appState.isUserEnrolled = true
                    }
                )
                .environmentObject(appState.authenticationService)
                .environmentObject(appState.healthKitService)
                .environmentObject(appState.dataManager)
            } else {
                // Show main app
                AuthenticatedAppView()
                    .environmentObject(appState.authenticationService)
                    .environmentObject(appState.healthKitService)
                    .environmentObject(appState.dataManager)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .scaleEffect(animationPhase == 0 ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animationPhase)
            
            Text("HeartID")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Initializing...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Setup Required")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                // Retry initialization
                Task {
                    await AppState().initialize()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Enrollment View

struct EnrollmentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEnrolling = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Welcome to HeartID")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Set up your biometric authentication")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start Setup") {
                isEnrolling = true
                // Start enrollment process
            }
            .buttonStyle(.borderedProminent)
            .disabled(isEnrolling)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Authenticated App View

struct AuthenticatedAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 1 // Start with Menu tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Landing Tab
            LandingTabView()
                .tag(0)
            
            // Menu Tab (Primary)
            MenuView()
                .tag(1)
            
            // Enroll Tab
            EnrollView()
                .tag(2)
            
            // Authenticate Tab
            AuthenticateView()
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

// MARK: - Landing Tab View

struct LandingTabView: View {
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
            
            // Status indicator
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
                
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            showContent = true
        }
    }
}