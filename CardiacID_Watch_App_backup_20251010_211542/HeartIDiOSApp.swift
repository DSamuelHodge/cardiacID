//
//  HeartIDiOSApp.swift
//  HeartID Watch App
//
//  Watch app with simplified connectivity
//

import SwiftUI
#if os(iOS)
import WatchConnectivity
#endif

struct HeartIDiOSApp: App {
    @StateObject private var watchConnectivityService = WatchConnectivityService()
    @StateObject private var dataManager = DataManager()
    @StateObject private var authenticationService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .environmentObject(watchConnectivityService)
                .environmentObject(dataManager)
                .environmentObject(authenticationService)
                .onAppear {
                    initializeApp()
                }
        }
    }
    
    private func initializeApp() {
        print("📱 HeartID iOS App initializing...")
        
        // Connect services
        authenticationService.setDataManager(dataManager)
        
        // Start Watch Connectivity
        watchConnectivityService.startSession()
        
        print("✅ HeartID iOS App initialization complete")
    }
}

// MARK: - iOS Main Content View

struct iOSContentView: View {
    @EnvironmentObject var watchConnectivityService: WatchConnectivityService
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authenticationService: AuthenticationService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Watch Status Tab
            WatchStatusView()
                .tabItem {
                    Image(systemName: "applewatch")
                    Text("Watch")
                }
                .tag(1)
            
            // Settings Tab
            iOSSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(3)
        }
        .tint(.red)
    }
}

// MARK: - iOS Views

struct DashboardView: View {
    @EnvironmentObject var watchConnectivityService: WatchConnectivityService
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authenticationService: AuthenticationService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("HeartID")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Biometric Authentication")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Status Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatusCard(
                            title: "Watch Status",
                            value: watchConnectivityService.isWatchConnected ? "Connected" : "Disconnected",
                            icon: "applewatch",
                            color: watchConnectivityService.isWatchConnected ? .green : .orange
                        )
                        
                        StatusCard(
                            title: "Enrollment",
                            value: dataManager.isUserEnrolled ? "Complete" : "Required",
                            icon: "person.badge.plus",
                            color: dataManager.isUserEnrolled ? .blue : .red
                        )
                        
                        StatusCard(
                            title: "Security Level",
                            value: dataManager.currentSecurityLevel.rawValue,
                            icon: "lock.shield",
                            color: .purple
                        )
                        
                        StatusCard(
                            title: "Auth Count",
                            value: "\(dataManager.authenticationCount)",
                            icon: "checkmark.shield",
                            color: .green
                        )
                    }
                    
                    // Recent Activity
                    if dataManager.isUserEnrolled {
                        RecentActivityView()
                    } else {
                        EnrollmentPromptView()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                // Refresh data from watch
                watchConnectivityService.requestDataSync()
            }
        }
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RecentActivityView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let lastAuth = dataManager.lastAuthenticationDate {
                    ActivityRow(
                        title: "Last Authentication",
                        subtitle: formatDate(lastAuth),
                        icon: "checkmark.shield",
                        color: .green
                    )
                }
                
                if let enrollmentDate = dataManager.enrollmentDate {
                    ActivityRow(
                        title: "Enrolled",
                        subtitle: formatDate(enrollmentDate),
                        icon: "person.badge.plus",
                        color: .blue
                    )
                }
                
                // Show authentication count if available
                if dataManager.authenticationCount > 0 {
                    ActivityRow(
                        title: "Total Authentications",
                        subtitle: "\(dataManager.authenticationCount)",
                        icon: "chart.bar",
                        color: .orange
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct EnrollmentPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Enrollment Required")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Please complete enrollment on your Apple Watch to start using HeartID authentication.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Text("Open the HeartID app on your watch and follow the enrollment process.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WatchStatusView: View {
    @EnvironmentObject var watchConnectivityService: WatchConnectivityService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Watch Connection Status
                    ConnectionStatusView()
                    
                    // Watch App Status
                    WatchAppStatusView()
                    
                    // Data Sync Controls
                    DataSyncControlsView()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Watch Status")
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var watchConnectivityService: WatchConnectivityService
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: watchConnectivityService.isWatchConnected ? "applewatch" : "applewatch.slash")
                .font(.system(size: 50))
                .foregroundColor(watchConnectivityService.isWatchConnected ? .green : .red)
            
            Text(watchConnectivityService.isWatchConnected ? "Watch Connected" : "Watch Disconnected")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(watchConnectivityService.connectionStatus)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(watchConnectivityService.isWatchConnected ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WatchAppStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch App Status")
                .font(.headline)
                .fontWeight(.bold)
            
            // Placeholder for watch app status info
            Text("HeartID app is installed and ready")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DataSyncControlsView: View {
    @EnvironmentObject var watchConnectivityService: WatchConnectivityService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Data Sync")
                .font(.headline)
                .fontWeight(.bold)
            
            Button("Sync Data from Watch") {
                watchConnectivityService.requestDataSync()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!watchConnectivityService.isWatchConnected)
            
            if let lastSync = watchConnectivityService.lastSyncDate {
                Text("Last sync: \(formatSyncDate(lastSync))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct iOSSettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Security") {
                    NavigationLink("Security Level") {
                        SecurityLevelSettingsView()
                    }
                    
                    NavigationLink("Authentication Frequency") {
                        AuthFrequencySettingsView()
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { dataManager.userPreferences.enableNotifications },
                        set: { newValue in
                            var prefs = dataManager.userPreferences
                            prefs.enableNotifications = newValue
                            dataManager.saveUserPreferences(prefs)
                        }
                    ))
                    
                    Toggle("Enable Alarms", isOn: Binding(
                        get: { dataManager.userPreferences.enableAlarms },
                        set: { newValue in
                            var prefs = dataManager.userPreferences
                            prefs.enableAlarms = newValue
                            dataManager.saveUserPreferences(prefs)
                        }
                    ))
                }
                
                Section("Advanced") {
                    Toggle("Background Authentication", isOn: Binding(
                        get: { dataManager.userPreferences.enableBackgroundAuthentication },
                        set: { newValue in
                            var prefs = dataManager.userPreferences
                            prefs.enableBackgroundAuthentication = newValue
                            dataManager.saveUserPreferences(prefs)
                        }
                    ))
                    
                    Toggle("Debug Mode", isOn: Binding(
                        get: { dataManager.userPreferences.debugMode },
                        set: { newValue in
                            var prefs = dataManager.userPreferences
                            prefs.debugMode = newValue
                            dataManager.saveUserPreferences(prefs)
                        }
                    ))
                }
                
                Section("Data Management") {
                    Button("Clear All Data", role: .destructive) {
                        dataManager.clearAllData()
                    }
                    
                    Button("Reset to Defaults") {
                        dataManager.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SecurityLevelSettingsView: View {
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
                    var prefs = dataManager.userPreferences
                    prefs.securityLevel = level
                    dataManager.saveUserPreferences(prefs)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                                .foregroundColor(.primary)
                            Text(level.description)
                                .font(.caption)
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
            selectedLevel = dataManager.userPreferences.securityLevel
        }
    }
}

struct AuthFrequencySettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFrequency: UserPreferences.AuthenticationFrequency
    
    init() {
        _selectedFrequency = State(initialValue: .moderate)
    }
    
    var body: some View {
        List {
            ForEach(UserPreferences.AuthenticationFrequency.allCases, id: \.self) { frequency in
                Button {
                    selectedFrequency = frequency
                    var prefs = dataManager.userPreferences
                    prefs.authenticationFrequency = frequency
                    dataManager.saveUserPreferences(prefs)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(frequency.rawValue)
                                .foregroundColor(.primary)
                            Text("Every \(frequency.minIntervalMinutes) minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFrequency == frequency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Auth Frequency")
        .onAppear {
            selectedFrequency = dataManager.userPreferences.authenticationFrequency
        }
    }
}

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if dataManager.isUserEnrolled {
                        // Statistics Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            AnalyticsCard(
                                title: "Days Enrolled",
                                value: "\(dataManager.enrollmentDate?.daysSince ?? 0)",
                                icon: "calendar",
                                color: .blue
                            )
                            
                            AnalyticsCard(
                                title: "Total Auths",
                                value: "\(dataManager.authenticationCount)",
                                icon: "checkmark.shield",
                                color: .green
                            )
                            
                            AnalyticsCard(
                                title: "Failed Attempts",
                                value: "0", // Not tracked in current DataManager
                                icon: "xmark.shield",
                                color: .red
                            )
                            
                            AnalyticsCard(
                                title: "Security Level",
                                value: dataManager.currentSecurityLevel.rawValue,
                                icon: "lock.shield",
                                color: .purple
                            )
                        }
                        
                        // Usage Patterns
                        UsagePatternsView()
                        
                    } else {
                        NoDataView()
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct UsagePatternsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Patterns")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let lastAuthDate = dataManager.lastAuthenticationDate {
                    let daysSinceLastAuth = lastAuthDate.daysSince
                    PatternRow(
                        title: "Days Since Last Auth",
                        value: "\(daysSinceLastAuth)",
                        color: daysSinceLastAuth > 7 ? .orange : .green
                    )
                }
                
                if dataManager.authenticationCount > 0 {
                    let enrollmentDays = max(dataManager.enrollmentDate?.daysSince ?? 1, 1)
                    let avgPerDay = Double(dataManager.authenticationCount) / Double(enrollmentDays)
                    PatternRow(
                        title: "Avg Auths per Day",
                        value: String(format: "%.1f", avgPerDay),
                        color: .blue
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PatternRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct NoDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Analytics Available")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Complete enrollment on your Apple Watch to start tracking authentication analytics.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Watch Connectivity Service for iOS

class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isWatchConnected = false
    @Published var connectionStatus = "Checking connection..."
    @Published var lastSyncDate: Date?
    @Published var lastAuthStatus: UserAuthStatus?
    @Published var lastAuthConfidence: Double?
    @Published var lastAuthMessage: String?
    @Published var lastAuthSuccess: Bool?
    
    #if os(iOS)
    private let session = WCSession.default
    #endif
    
    /// Validate authentication result payload from watch
    private func validateAuthPayload(_ payload: [String: Any]) -> Bool {
        guard payload["type"] as? String == "authenticationResult" else { return false }
        guard let status = payload["status"] as? String else { return false }
        // status must be one of the known values
        let allowed = ["approved", "denied", "pending", "error"]
        guard allowed.contains(status) else { return false }
        // confidence is optional but must be a number if present
        if let confidence = payload["confidence"] {
            if !(confidence is Double) && !(confidence is NSNumber) { return false }
        }
        // isSuccessful is optional bool; tolerate absence
        if let isSuccessful = payload["isSuccessful"] {
            if !(isSuccessful is Bool) { return false }
        }
        return true
    }
    
    func startSession() {
        #if os(iOS)
        guard WCSession.isSupported() else {
            connectionStatus = "Watch Connectivity not supported"
            return
        }
        
        session.activate()
        #else
        connectionStatus = "Watch app - no connectivity needed"
        isWatchConnected = true
        #endif
    }
    
    func requestDataSync() {
        #if os(iOS)
        guard session.isReachable else {
            connectionStatus = "Watch not reachable"
            return
        }
        
        let message: [String: Any] = ["action": "syncData", "timestamp": Date().timeIntervalSince1970]
        
        session.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.lastSyncDate = Date()
                print("📱 Data sync completed: \(reply)")
            }
        }) { [weak self] error in
            DispatchQueue.main.async {
                self?.connectionStatus = "Sync failed: \(error.localizedDescription)"
                print("❌ Data sync failed: \(error)")
            }
        }
        #else
        // Watch app - no need to sync with itself
        lastSyncDate = Date()
        connectionStatus = "Watch app - sync complete"
        #endif
    }
}

#if os(iOS)
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.connectionStatus = "Connected"
                self.isWatchConnected = session.isWatchAppInstalled
            case .inactive:
                self.connectionStatus = "Inactive"
                self.isWatchConnected = false
            case .notActivated:
                self.connectionStatus = "Not activated"
                self.isWatchConnected = false
            @unknown default:
                self.connectionStatus = "Unknown state"
                self.isWatchConnected = false
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStatus = "Session became inactive"
            self.isWatchConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStatus = "Session deactivated"
            self.isWatchConnected = false
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
            self.connectionStatus = session.isReachable ? "Connected and reachable" : "Connected but not reachable"
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Received message from watch: \(message)")

        // Prefer new typed payloads
        if let type = message["type"] as? String {
            switch type {
            case "authenticationResult":
                // Validate payload
                guard validateAuthPayload(message) else {
                    DispatchQueue.main.async {
                        self.connectionStatus = "Invalid auth payload"
                    }
                    return
                }
                let statusRaw = message["status"] as? String ?? "error"
                let confidence = (message["confidence"] as? NSNumber)?.doubleValue
                let msg = message["message"] as? String
                let success = message["isSuccessful"] as? Bool

                // Map to UserAuthStatus
                let status = UserAuthStatus(rawValue: statusRaw) ?? .error

                DispatchQueue.main.async {
                    self.lastAuthStatus = status
                    self.lastAuthConfidence = confidence
                    self.lastAuthMessage = msg
                    self.lastAuthSuccess = success ?? (status == .approved)
                    self.lastSyncDate = Date()
                    self.connectionStatus = "Auth: \(status.rawValue)"
                }
                return
            case "enrollmentStatus":
                // Handle enrollment status update
                let isEnrolled = message["isEnrolled"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.connectionStatus = isEnrolled ? "Watch enrolled" : "Enrollment required"
                }
                return
            default:
                break
            }
        }

        // Legacy fallback: action-based messages
        if let action = message["action"] as? String {
            switch action {
            case "enrollmentComplete":
                print("📱 Enrollment completed on watch")
            case "authenticationResult":
                if let result = message["result"] as? String {
                    print("📱 Authentication result from watch: \(result)")
                    let status = UserAuthStatus(rawValue: result) ?? .error
                    DispatchQueue.main.async {
                        self.lastAuthStatus = status
                        self.connectionStatus = "Auth: \(status.rawValue)"
                    }
                }
            default:
                print("📱 Unknown action from watch: \(action)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 Received message from watch (reply): \(message)")

        // Reuse the non-reply handler for parsing
        self.session(session, didReceiveMessage: message)

        // Always acknowledge
        replyHandler(["status": "received"])
    }
}
#endif

// MARK: - Date Extensions
extension Date {
    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
}

