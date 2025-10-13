// MARK: - MenuView Analysis & Fixes

import SwiftUI
import WatchKit

struct MenuView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var healthKitService: HealthKitService // Added missing dependency

    // Unified sheet router
    private enum SheetRoute: Hashable, Identifiable {
        case enroll, authenticate, settings, calibrate, security, alarm
        var id: Int { self.hashValue }
    }
    @State private var activeSheet: SheetRoute?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("HeartID")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Menu")
                            .font(.system(size: 12))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Enhanced status indicator
                        EnrollmentStatusView(isEnrolled: authenticationService.isUserEnrolled)
                    }
                    .padding(.bottom, 20)
                    
                    // Menu Items with enhanced validation
                    VStack(spacing: 12) {
                        MenuButton(
                            title: "Enroll",
                            icon: "person.badge.plus",
                            color: .blue,
                            isEnabled: !authenticationService.isUserEnrolled && healthKitService.isAuthorized
                        ) {
                            handleEnrollAction()
                        }
                        
                        MenuButton(
                            title: "Authenticate",
                            icon: "checkmark.shield",
                            color: .green,
                            isEnabled: authenticationService.isUserEnrolled && healthKitService.isAuthorized
                        ) {
                            handleAuthenticateAction()
                        }
                        
                        MenuButton(
                            title: "Calibrate",
                            icon: "tuningfork",
                            color: .purple,
                            isEnabled: authenticationService.isUserEnrolled && healthKitService.isAuthorized
                        ) {
                            activeSheet = .calibrate
                        }
                        
                        MenuButton(
                            title: "Security Level",
                            icon: "lock.shield",
                            color: .orange,
                            isEnabled: true
                        ) {
                            activeSheet = .security
                        }
                        
                        MenuButton(
                            title: "Alarm Notification",
                            icon: "bell",
                            color: .red,
                            isEnabled: true
                        ) {
                            activeSheet = .alarm
                        }
                        
                        MenuButton(
                            title: "Settings",
                            icon: "gear",
                            color: .gray,
                            isEnabled: true
                        ) {
                            activeSheet = .settings
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced Status Information
                    StatusInformationView(authenticationService: authenticationService)
                }
                .padding()
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Single, enum-driven sheet router with enhanced error handling
        .sheet(item: $activeSheet) { route in
            Group {
                switch route {
                case .enroll:        
                    EnrollView()
                        .environmentObject(healthKitService) // Ensure all dependencies are passed
                case .authenticate:  
                    AuthenticateView()
                        .environmentObject(healthKitService)
                case .settings:      
                    SettingsView()
                case .calibrate:     
                    CalibrateView()
                        .environmentObject(healthKitService)
                case .security:      
                    SecurityLevelView()
                case .alarm:         
                    AlarmNotificationView()
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("UserDeleted"))) { _ in
            // Refresh the view when user is deleted
        }
        // After a successful enrollment, auto-open Settings to complete setup
        .onReceive(NotificationCenter.default.publisher(for: .init("UserEnrolled"))) { _ in
            // Delay to ensure enrollment sheet is dismissed first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                activeSheet = .settings
            }
        }
        .onAppear {
            // Ensure all services are properly initialized
            initializeServices()
        }
    }
    
    // MARK: - Action Handlers
    private func handleEnrollAction() {
        // Haptic feedback for button press
        WKInterfaceDevice.current().play(.click)
        
        guard healthKitService.isAuthorized else {
            errorMessage = "HealthKit authorization is required for enrollment. Please enable in Settings."
            showingError = true
            return
        }
        
        if authenticationService.dataManager == nil {
            authenticationService.setDataManager(dataManager)
        }
        activeSheet = .enroll
    }
    
    private func handleAuthenticateAction() {
        // Haptic feedback for button press
        WKInterfaceDevice.current().play(.click)
        
        guard healthKitService.isAuthorized else {
            errorMessage = "HealthKit authorization is required for authentication. Please enable in Settings."
            showingError = true
            return
        }
        
        guard authenticationService.isUserEnrolled else {
            errorMessage = "You must enroll first before authenticating."
            showingError = true
            return
        }
        
        activeSheet = .authenticate
    }
    
    private func initializeServices() {
        // Ensure data manager is connected to authentication service
        if authenticationService.dataManager == nil {
            authenticationService.setDataManager(dataManager)
        }
        
        // Check HealthKit authorization if not already done
        if !healthKitService.isAuthorized {
            Task {
                let success = await healthKitService.requestAuthorization()
                if !success {
                    // Handle authorization failure
                }
            }
        }
    }
}

// MARK: - Enhanced Component Views

struct EnrollmentStatusView: View {
    let isEnrolled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isEnrolled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isEnrolled ? .green : .orange)
            
            Text(isEnrolled ? "Enrolled" : "Not Enrolled")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isEnrolled ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
}

struct StatusInformationView: View {
    let authenticationService: AuthenticationService
    
    var body: some View {
        if authenticationService.isUserEnrolled {
            VStack(spacing: 8) {
                Text("Authentication Status")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(authenticationService.isAuthenticated ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(authenticationService.isAuthenticated ? "Authenticated" : "Not Authenticated")
                        .font(.caption)
                }
                
                if let lastResult = authenticationService.lastAuthenticationResult {
                    Text("Last Result: \(lastResult.message)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Add helpful tips
                if !authenticationService.isAuthenticated {
                    Text("Tap Authenticate to verify your identity")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .italic()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback for button press
            WKInterfaceDevice.current().play(.click)
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? color : .gray)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .gray)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) button")
        .accessibilityHint(isEnabled ? "Tap to \(title.lowercased())" : "\(title) is not available")
    }
}

// MARK: - Supporting Views

struct CalibrateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var calibrationState: CalibrationState = .ready
    @State private var progress: Double = 0
    @State private var errorMessage: String?
    
    enum CalibrationState: Equatable {
        case ready, inProgress, completed, error(String)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "tuningfork")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                
                Text("Calibration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Calibration helps improve authentication accuracy by analyzing your heart pattern in different conditions.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                switch calibrationState {
                case .ready:
                    VStack(spacing: 12) {
                        Text("This process will take 30 seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Start Calibration") {
                            startCalibration()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!healthKitService.isAuthorized)
                    }
                    
                case .inProgress:
                    VStack(spacing: 12) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Calibrating... \(Int(progress * 100))%")
                            .font(.caption)
                        
                        Text("Keep your watch on and stay still")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                case .completed:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        Text("Calibration Complete")
                            .font(.headline)
                        
                        Text("Your authentication accuracy has been improved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                case .error(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        
                        Text("Calibration Failed")
                            .font(.headline)
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            calibrationState = .ready
                            errorMessage = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                if !healthKitService.isAuthorized && calibrationState == .ready {
                    Text("HealthKit access required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Calibrate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startCalibration() {
        guard healthKitService.isAuthorized else {
            calibrationState = .error("HealthKit authorization required")
            return
        }
        
        calibrationState = .inProgress
        progress = 0
        
        // Simulate calibration process
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            progress += 0.02
            if progress >= 1.0 {
                timer.invalidate()
                calibrationState = .completed
            }
        }
    }
}

struct SecurityLevelView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedLevel: SecurityLevel
    
    init() {
        _selectedLevel = State(initialValue: .medium)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Security Level")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose your preferred security level. Higher levels provide more security but may require more precise heart pattern matching.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        ForEach(SecurityLevel.allCases, id: \.self) { level in
                            SecurityLevelRow(
                                level: level,
                                isSelected: selectedLevel == level
                            ) {
                                selectedLevel = level
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Save Security Level") {
                        var preferences = dataManager.userPreferences
                        preferences.securityLevel = selectedLevel
                        dataManager.saveUserPreferences(preferences)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedLevel == dataManager.userPreferences.securityLevel)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Security Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedLevel = dataManager.userPreferences.securityLevel
        }
    }
}

struct SecurityLevelRow: View {
    let level: SecurityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlarmNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var enableAlarms: Bool
    @State private var enableNotifications: Bool
    
    init() {
        _enableAlarms = State(initialValue: true)
        _enableNotifications = State(initialValue: true)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Alarm & Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        Toggle("Enable Alarms", isOn: $enableAlarms)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Toggle("Enable Notifications", isOn: $enableNotifications)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    Button("Save Settings") {
                        var preferences = dataManager.userPreferences
                        preferences.enableAlarms = enableAlarms
                        preferences.enableNotifications = enableNotifications
                        dataManager.userPreferences = preferences
                        dataManager.saveUserPreferences(preferences)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Alarms & Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            enableAlarms = dataManager.userPreferences.enableAlarms
            enableNotifications = dataManager.userPreferences.enableNotifications
        }
    }
}

struct MenuProcessingStateView: View {
    let progress: Double
    let title: String
    
    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    MenuView()
        .environmentObject(AuthenticationService())
        .environmentObject(DataManager.shared)
}
