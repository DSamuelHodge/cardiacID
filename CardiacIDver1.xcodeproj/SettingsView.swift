//
//  SettingsView.swift
//  HeartID Watch App
//
//  Settings view for watchOS app
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                // Settings Options
                VStack(spacing: 12) {
                    SettingRow(
                        icon: "heart.fill",
                        title: "Health Data",
                        value: "Enabled"
                    )
                    
                    SettingRow(
                        icon: "shield.fill",
                        title: "Security",
                        value: "Active"
                    )
                    
                    SettingRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        value: "On"
                    )
                    
                    SettingRow(
                        icon: "info.circle.fill",
                        title: "About",
                        value: "v0.4"
                    )
                }
                
                Spacer(minLength: 30)
                
                // App Info
                VStack(spacing: 4) {
                    Text("HeartID for Apple Watch")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Biometric Authentication")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Setting Row Component

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}