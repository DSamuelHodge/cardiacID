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
                    // Initialize app state asynchronously
                    Task {
                        await appState.initialize()
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
    
    private let dataManager = DataManager.shared
    
    func initialize() async {
        // Check enrollment status first (fast operation)
        isUserEnrolled = dataManager.isUserEnrolled
        
        // Check HealthKit availability (non-blocking)
        healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        
        // Request HealthKit authorization asynchronously if needed
        if healthKitAvailable && !isUserEnrolled {
            await requestHealthKitAuthorization()
        }
        
        isInitialized = true
    }
    
    private func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        do {
            let success = try await HKHealthStore().requestAuthorization(toShare: nil, read: typesToRead)
            if !success {
                errorMessage = "HealthKit authorization denied"
            }
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
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
                EnrollmentView()
            } else {
                // Show main app
                AuthenticatedAppView()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("HeartID")
                .font(.headline)
                .fontWeight(.bold)
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Authentication Tab
            AuthenticationTabView()
                .tag(0)
            
            // Settings Tab
            SettingsTabView()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

// MARK: - Authentication Tab

struct AuthenticationTabView: View {
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("HeartID")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Authenticate") {
                isAuthenticating = true
                // Start authentication process
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Configure your HeartID")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}