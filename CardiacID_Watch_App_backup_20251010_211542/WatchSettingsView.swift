//
//  WatchSettingsView.swift
//  HeartID Watch App
//
//  Settings view optimized for watchOS
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var showingClearDataAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Security Settings
                Section("Security") {
                    NavigationLink("Security Level") {
                        SecurityLevelWatchView()
                    }
                    
                    HStack {
                        Text("Current Level")
                        Spacer()
                        Text(dataManager.currentSecurityLevel.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Authentication Settings
                Section("Authentication") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(authenticationService.isUserEnrolled ? "Enrolled" : "Not Enrolled")
                            .foregroundColor(authenticationService.isUserEnrolled ? .green : .orange)
                    }
                    
                    if authenticationService.isUserEnrolled {
                        HStack {
                            Text("Last Auth")
                            Spacer()
                            Text(formatLastAuth())
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Auths")
                            Spacer()
                            Text("\(dataManager.authenticationCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // HealthKit Settings
                Section("HealthKit") {
                    HStack {
                        Text("Authorization")
                        Spacer()
                        Text(healthKitService.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(healthKitService.isAuthorized ? .green : .red)
                    }
                    
                    if !healthKitService.isAuthorized {
                        Button("Request Authorization") {
                            healthKitService.requestAuthorization()
                        }
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(healthKitService.getAuthorizationStatus())
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // Data Management
                Section("Data") {
                    Button("Clear All Data", role: .destructive) {
                        showingClearDataAlert = true
                    }
                    
                    Button("Reset to Defaults") {
                        showingResetAlert = true
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.3.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("25")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Clear", role: .destructive) {
                dataManager.clearAllData()
                authenticationService.clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all enrollment data and settings. This action cannot be undone.")
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                dataManager.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all settings to their default values. Your enrollment data will be preserved.")
        }
    }
    
    private func formatLastAuth() -> String {
        guard let lastAuth = dataManager.lastAuthenticationDate else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastAuth, relativeTo: Date())
    }
}

struct SecurityLevelWatchView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedLevel: SecurityLevel
    
    init() {
        _selectedLevel = State(initialValue: .medium)
    }
    
    var body: some View {
        List {
            ForEach(SecurityLevel.allCases, id: \.self) { level in
                Button {
                    selectedLevel = level
                    var preferences = dataManager.userPreferences
                    preferences.securityLevel = level
                    dataManager.saveUserPreferences(preferences)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(level.rawValue)
                                .foregroundColor(.primary)
                            Text(level.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Security Level")
        .onAppear {
            selectedLevel = dataManager.currentSecurityLevel
        }
    }
}

#Preview {
    NavigationView {
        WatchSettingsView()
            .environmentObject(DataManager())
            .environmentObject(AuthenticationService())
            .environmentObject(HealthKitService())
    }
}