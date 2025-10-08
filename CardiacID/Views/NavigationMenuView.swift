//
//  NavigationMenuView.swift
//  HeartID Mobile
//
//  Created by Jim Locke on 9/9/25.
//

import SwiftUI

struct NavigationMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedDestination: ViewDestination?
    
    private let colors = HeartIDColors()
    
    // All available views organized by category
    private let viewCategories = [
        ViewCategory(
            title: "Authentication",
            views: [
                ViewItem(title: "Login", icon: "person.circle", destination: .login),
                ViewItem(title: "Enterprise Auth", icon: "building.2", destination: .enterpriseAuth),
                ViewItem(title: "Passwordless Auth", icon: "key", destination: .passwordlessAuth),
                ViewItem(title: "Enrollment", icon: "person.badge.plus", destination: .enrollment)
            ]
        ),
        ViewCategory(
            title: "Main App",
            views: [
                ViewItem(title: "Dashboard", icon: "heart.fill", destination: .dashboard),
                ViewItem(title: "Profile", icon: "person", destination: .profile),
                ViewItem(title: "Activity Log", icon: "chart.line.uptrend.xyaxis", destination: .activityLog)
            ]
        ),
        ViewCategory(
            title: "Device Management",
            views: [
                ViewItem(title: "Device Management", icon: "applewatch", destination: .deviceManagement),
                ViewItem(title: "Technology Management", icon: "network", destination: .technologyManagement)
            ]
        ),
        ViewCategory(
            title: "Settings & Security",
            views: [
                ViewItem(title: "Settings", icon: "gear", destination: .settings),
                ViewItem(title: "Security Settings", icon: "lock.shield", destination: .securitySettings),
                ViewItem(title: "Lockout Settings", icon: "lock.rotation", destination: .lockoutSettings)
            ]
        ),
        ViewCategory(
            title: "Debug & Development",
            views: [
                ViewItem(title: "Debug Panel", icon: "wrench.and.screwdriver", destination: .debugPanel)
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundColor(colors.accent)
                            
                            Text("HeartID Navigation")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colors.text)
                            
                            Text("Access all app screens")
                                .font(.subheadline)
                                .foregroundColor(colors.secondary)
                        }
                        .padding(.top, 20)
                        
                        // View Categories
                        ForEach(viewCategories, id: \.title) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.title)
                                    .font(.headline)
                                    .foregroundColor(colors.accent)
                                    .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(category.views, id: \.title) { viewItem in
                                        Button(action: {
                                            selectedDestination = viewItem.destination
                                        }) {
                                            HStack(spacing: 15) {
                                                Image(systemName: viewItem.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(colors.accent)
                                                    .frame(width: 30)
                                                
                                                Text(viewItem.title)
                                                    .font(.body)
                                                    .foregroundColor(colors.text)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(colors.secondary)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(colors.surface)
                                            .cornerRadius(10)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(colors.accent)
                }
            }
        }
        .sheet(item: $selectedDestination) { destination in
            NavigationView {
                destinationView(for: destination)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedDestination = nil
                            }
                            .foregroundColor(colors.accent)
                        }
                    }
            }
        }
    }
    
    private func viewDescription(for destination: ViewDestination) -> String {
        switch destination {
        case .login: return "Sign in to your account"
        case .enterpriseAuth: return "Enterprise authentication"
        case .passwordlessAuth: return "Passwordless authentication methods"
        case .enrollment: return "Enroll your device"
        case .dashboard: return "Main app dashboard"
        case .profile: return "User profile settings"
        case .activityLog: return "View activity history"
        case .deviceManagement: return "Manage connected devices"
        case .technologyManagement: return "Technology integrations"
        case .settings: return "App settings"
        case .securitySettings: return "Security preferences"
        case .lockoutSettings: return "Lockout configuration"
        case .debugPanel: return "Debug information"
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: ViewDestination) -> some View {
        switch destination {
        case .login:
            LoginView()
                .environmentObject(authViewModel)
        case .enterpriseAuth:
            EnterpriseAuthView(entraIDService: EntraIDService(tenantId: "test-tenant", clientId: "test-client", redirectUri: "test://redirect"))
        case .passwordlessAuth:
            PasswordlessAuthView()
        case .enrollment:
            EnrollmentView()
        case .dashboard:
            DashboardView()
        case .profile:
            ProfileView()
        case .activityLog:
            ActivityLogView()
        case .deviceManagement:
            DeviceManagementView()
        case .technologyManagement:
            TechnologyManagementView()
        case .settings:
            SettingsView()
        case .securitySettings:
            SecuritySettingsView()
        case .lockoutSettings:
            LockoutSettingsView()
                .environmentObject(authViewModel)
        case .debugPanel:
            DebugPanelView()
        }
    }
}

// MARK: - Supporting Types

struct ViewCategory {
    let title: String
    let views: [ViewItem]
}

struct ViewItem {
    let title: String
    let icon: String
    let destination: ViewDestination
}

enum ViewDestination: Identifiable {
    case login
    case enterpriseAuth
    case passwordlessAuth
    case enrollment
    case dashboard
    case profile
    case activityLog
    case deviceManagement
    case technologyManagement
    case settings
    case securitySettings
    case lockoutSettings
    case debugPanel
    
    var id: String {
        switch self {
        case .login: return "login"
        case .enterpriseAuth: return "enterpriseAuth"
        case .passwordlessAuth: return "passwordlessAuth"
        case .enrollment: return "enrollment"
        case .dashboard: return "dashboard"
        case .profile: return "profile"
        case .activityLog: return "activityLog"
        case .deviceManagement: return "deviceManagement"
        case .technologyManagement: return "technologyManagement"
        case .settings: return "settings"
        case .securitySettings: return "securitySettings"
        case .lockoutSettings: return "lockoutSettings"
        case .debugPanel: return "debugPanel"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationMenuView(isPresented: .constant(true))
        .environmentObject(AuthViewModel())
}
