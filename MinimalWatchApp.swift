//
//  X_MinimalWatchApp.swift
//  HeartID Watch App
//
//  ❌ DISABLED - Fallback minimal app for troubleshooting build issues
//  🗑️ SAFE TO DELETE - This is only needed for troubleshooting
//

import SwiftUI
import HealthKit

// MARK: - Minimal App Entry Point (Fallback) - DISABLED

/*
 ❌ DISABLED - Use this as a temporary replacement for HeartIDWatchApp.swift
 if you're experiencing build issues. Once build is working,
 switch back to the full HeartIDWatchApp.swift implementation.
 
 Currently disabled to resolve multiple @main attribute conflicts.
*/

/*
// @main - DISABLED
struct X_MinimalHeartIDApp_DISABLED: App {
    var body: some Scene {
        WindowGroup {
            MinimalContentView()
        }
    }
}

struct MinimalContentView: View {
    @StateObject private var healthService = HealthKitService()
    @StateObject private var authService = AuthenticationService()
    @State private var showingEnroll = false
    @State private var showingAuth = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text("HeartID")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Status
                Text(authService.isUserEnrolled ? "Enrolled" : "Not Enrolled")
                    .font(.caption)
                    .foregroundColor(authService.isUserEnrolled ? .green : .orange)
                
                // Basic Actions
                VStack(spacing: 12) {
                    if !authService.isUserEnrolled {
                        Button("Enroll") {
                            showingEnroll = true
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Authenticate") {
                            showingAuth = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Re-enroll") {
                            showingEnroll = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("HeartID")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingEnroll) {
            EnrollView()
                .environmentObject(authService)
                .environmentObject(healthService)
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticateView()
                .environmentObject(authService)
                .environmentObject(healthService)
        }
    }
}

// MARK: - Minimal Error Handling

struct MinimalErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Setup Required")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("OK") {
                // Handle error acknowledgment
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

*/ // End of disabled MinimalWatchApp.swift
        .padding()
    }
}