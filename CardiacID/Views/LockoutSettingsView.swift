import SwiftUI

struct LockoutSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var settings: LockoutSettings
    @State private var showingResetConfirmation = false
    
    private let colors = HeartIDColors()
    
    init() {
        // Load settings from UserDefaults or use defaults
        if let data = UserDefaults.standard.data(forKey: "lockoutSettings"),
           let decoded = try? JSONDecoder().decode(LockoutSettings.self, from: data) {
            _settings = State(initialValue: decoded)
        } else {
            _settings = State(initialValue: LockoutSettings())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50))
                            .foregroundColor(colors.accent)
                        
                        Text("Login Attempt Lockout")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text("Configure progressive lockout periods for failed login attempts")
                            .font(.subheadline)
                            .foregroundColor(colors.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Enable/Disable Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Login Lockout", isOn: $settings.isEnabled)
                            .font(.headline)
                            .foregroundColor(colors.text)
                        
                        Text("When enabled, failed login attempts will trigger progressive lockout periods")
                            .font(.caption)
                            .foregroundColor(colors.text.opacity(0.7))
                    }
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
                    
                    if settings.isEnabled {
                        // Attempts per Period
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attempts per Period")
                                .font(.headline)
                                .foregroundColor(colors.text)
                            
                            Stepper(value: $settings.maxAttemptsPerPeriod, in: 1...5) {
                                Text("\(settings.maxAttemptsPerPeriod) attempts before lockout")
                                    .foregroundColor(colors.text)
                            }
                            
                            Text("Number of failed attempts allowed before triggering lockout")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.7))
                        }
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(12)
                        
                        // Lockout Periods
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Lockout Periods")
                                .font(.headline)
                                .foregroundColor(colors.text)
                            
                            Toggle("Use Custom Periods", isOn: $settings.useCustomPeriods)
                                .font(.subheadline)
                                .foregroundColor(colors.text)
                            
                            if settings.useCustomPeriods {
                                customPeriodsView
                            } else {
                                defaultPeriodsView
                            }
                        }
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(12)
                        
                        // Current Status
                        currentStatusView
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle("Lockout Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Lockout Status", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetLockoutStatus()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the current lockout status and allow immediate login attempts. Are you sure?")
        }
    }
    
    // MARK: - Custom Periods View
    
    private var customPeriodsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Lockout Periods (in minutes)")
                .font(.subheadline)
                .foregroundColor(colors.text)
            
            ForEach(0..<settings.customPeriods.count, id: \.self) { index in
                HStack {
                    Text("Period \(index + 1):")
                        .font(.caption)
                        .foregroundColor(colors.text.opacity(0.7))
                        .frame(width: 60, alignment: .leading)
                    
                    TextField("Minutes", value: $settings.customPeriods[index], format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            
            HStack {
                Button("Add Period") {
                    settings.customPeriods.append(60) // Default 1 hour
                }
                .buttonStyle(.bordered)
                
                if settings.customPeriods.count > 1 {
                    Button("Remove Last") {
                        settings.customPeriods.removeLast()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Default Periods View
    
    private var defaultPeriodsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Lockout Schedule")
                .font(.subheadline)
                .foregroundColor(colors.text)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(settings.lockoutPeriods.enumerated()), id: \.offset) { index, period in
                    HStack {
                        Text("Period \(index + 1):")
                            .font(.caption)
                            .foregroundColor(colors.text.opacity(0.7))
                            .frame(width: 60, alignment: .leading)
                        
                        Text(formatPeriod(period))
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Current Status View
    
    private var currentStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
                .foregroundColor(colors.text)
            
            if authViewModel.loginAttemptTracker.isLockedOut {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Locked")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        if let timeRemaining = authViewModel.loginAttemptTracker.getFormattedTimeRemaining() {
                            Text("Unlocks in \(timeRemaining)")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.7))
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Status: Normal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("\(authViewModel.loginAttemptTracker.remainingAttempts) attempts remaining")
                            .font(.caption)
                            .foregroundColor(colors.text.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("Reset Lockout Status") {
                showingResetConfirmation = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func formatPeriod(_ minutes: TimeInterval) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "lockoutSettings")
        }
    }
    
    private func resetLockoutStatus() {
        authViewModel.loginAttemptTracker.recordSuccessfulAttempt()
    }
}

#Preview {
    LockoutSettingsView()
        .environmentObject(AuthViewModel())
}
