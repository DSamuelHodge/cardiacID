//
//  X_HeartIDApp.swift
//  HeartID Watch App
//
//  ❌ DISABLED - This entire file is disabled to avoid @main conflicts
//  🗑️ SAFE TO DELETE - The active app entry point is in HeartIDWatchApp.swift
//
//  This file contains a complete app implementation that is currently 
//  disabled by commenting out the entire content.

#if false
// Entire file content disabled

import SwiftUI
import HealthKit

// @main - DISABLED
struct X_HeartIDWatchApp_DISABLED: App {
    
    // MARK: - Service Instances
    
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var dataManager = DataManager()
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var enhancedAuthService: EnhancedAuthenticationService
    
    // MARK: - App Initialization
    
    init() {
        print("🚀 Initializing HeartID Watch App")
        
        // Initialize enhanced authentication service with base service
        let baseAuthService = AuthenticationService()
        _enhancedAuthService = StateObject(wrappedValue: EnhancedAuthenticationService(baseAuthService: baseAuthService))
        
        print("✅ HeartID Watch App initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .environmentObject(dataManager)
                .environmentObject(authenticationService)
                .environmentObject(enhancedAuthService)
                .onAppear {
                    setupServices()
                }
                .task {
                    await initializeApp()
                }
        }
    }
    
    // MARK: - Service Setup
    
    private func setupServices() {
        print("🔧 Setting up services")
        
        // Inject dependencies
        authenticationService.setHealthKitService(healthKitService)
        authenticationService.setDataManager(dataManager)
        
        print("✅ Services configured")
    }
    
    private func initializeApp() async {
        print("📱 Initializing app components")
        
        // Request HealthKit authorization on app launch
        let authResult = await healthKitService.ensureAuthorization()
        
        switch authResult {
        case .authorized:
            print("✅ HealthKit authorized")
        case .denied(let reason):
            print("❌ HealthKit authorization denied: \(reason)")
        case .notAvailable(let reason):
            print("⚠️ HealthKit not available: \(reason)")
        }
        
        // Load user data
        if dataManager.isUserEnrolled() {
            print("👤 User is enrolled")
        } else {
            print("⚠️ User not enrolled")
        }
        
        print("✅ App initialization complete")
    }
}

// MARK: - Watch App Content View

struct ContentView: View {
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var enhancedAuthService: EnhancedAuthenticationService
    
    @State private var currentView: AppView = .dashboard
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentView) {
                // Dashboard
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "heart.fill")
                    }
                    .tag(AppView.dashboard)
                
                // Enrollment
                EnrollmentView()
                    .tabItem {
                        Label("Enroll", systemImage: "person.badge.plus")
                    }
                    .tag(AppView.enrollment)
                
                // Authentication
                AuthenticationView()
                    .tabItem {
                        Label("Authenticate", systemImage: "lock.shield")
                    }
                    .tag(AppView.authentication)
                
                // Settings
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(AppView.settings)
            }
        }
        .alert("System Alert", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .healthKitError)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                alertMessage = error
                showingAlert = true
            }
        }
    }
}

// MARK: - App Views Enum

enum AppView: String, CaseIterable {
    case dashboard = "Dashboard"
    case enrollment = "Enrollment" 
    case authentication = "Authentication"
    case settings = "Settings"
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let healthKitError = Notification.Name("healthKitError")
    static let authenticationUpdate = Notification.Name("authenticationUpdate")
    static let enrollmentUpdate = Notification.Name("enrollmentUpdate")
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var healthKitService: HealthKitService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status Card
                StatusCardView()
                
                // Quick Actions
                QuickActionsView()
                
                // Recent Activity
                RecentActivityView()
            }
            .padding()
        }
        .navigationTitle("HeartID")
    }
}

struct StatusCardView: View {
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var healthKitService: HealthKitService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: authenticationService.isAuthenticated ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(authenticationService.isAuthenticated ? .green : .orange)
                
                Text(authenticationService.isAuthenticated ? "Authenticated" : "Not Authenticated")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("HealthKit: \(healthKitService.authorizationStatus)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Enrolled: \(authenticationService.isUserEnrolled ? "Yes" : "No")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionsView: View {
    @EnvironmentObject private var authenticationService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                NavigationLink(destination: EnrollmentView()) {
                    ActionButtonView(
                        title: "Enroll",
                        icon: "person.badge.plus",
                        color: .blue,
                        isEnabled: !authenticationService.isUserEnrolled
                    )
                }
                .disabled(authenticationService.isUserEnrolled)
                
                NavigationLink(destination: AuthenticationView()) {
                    ActionButtonView(
                        title: "Authenticate",
                        icon: "lock.shield",
                        color: .green,
                        isEnabled: authenticationService.isUserEnrolled
                    )
                }
                .disabled(!authenticationService.isUserEnrolled)
            }
        }
    }
}

struct ActionButtonView: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
        .foregroundColor(isEnabled ? color : .gray)
        .cornerRadius(12)
    }
}

struct RecentActivityView: View {
    @EnvironmentObject private var authenticationService: AuthenticationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.headline)
            
            if let lastResult = authenticationService.lastAuthenticationResult {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Authentication")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(lastResult.message)
                        .font(.caption)
                        .foregroundColor(lastResult.isSuccessful ? .green : .red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Text("No recent activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var healthKitService: HealthKitService
    
    @State private var showingClearDataAlert = false
    @State private var showingDiagnostics = false
    @State private var diagnosticsText = ""
    
    var body: some View {
        List {
            Section("Security") {
                Picker("Security Level", selection: $dataManager.userPreferences.securityLevel) {
                    ForEach(SecurityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                
                Toggle("Background Authentication", isOn: $dataManager.userPreferences.enableBackgroundAuthentication)
            }
            
            Section("Data") {
                Button("Clear All Data") {
                    showingClearDataAlert = true
                }
                .foregroundColor(.red)
                
                Button("Run Diagnostics") {
                    Task {
                        diagnosticsText = await healthKitService.runHealthKitDiagnostics()
                        showingDiagnostics = true
                    }
                }
            }
            
            Section("Information") {
                HStack {
                    Text("Data Integrity")
                    Spacer()
                    Text(dataManager.dataIntegrityStatus.rawValue)
                        .foregroundColor(dataManager.dataIntegrityStatus.isHealthy ? .green : .red)
                }
                
                let stats = dataManager.getStorageStatistics()
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text(stats.formattedTotalSize)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                authenticationService.clearAllData()
            }
        } message: {
            Text("This will permanently delete all enrollment data and settings. This action cannot be undone.")
        }
        .sheet(isPresented: $showingDiagnostics) {
            NavigationView {
                ScrollView {
                    Text(diagnosticsText)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Diagnostics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDiagnostics = false
                        }
                    }
                }
            }
        }
    }
}

#endif // End of disabled HeartIDApp.swift