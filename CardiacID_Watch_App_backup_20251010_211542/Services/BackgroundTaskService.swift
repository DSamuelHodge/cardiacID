#if os(watchOS)
//
//  BackgroundTaskService.swift
//  HeartID Watch App
//
//  Service for managing background tasks and continuous authentication
//

import Foundation
import Combine
import WatchKit

/// Service for managing background tasks and continuous authentication monitoring
class BackgroundTaskService: NSObject, ObservableObject {
    @Published var isBackgroundTaskActive = false
    @Published var backgroundTaskStatus: BackgroundTaskStatus = .idle
    @Published var lastBackgroundCheck: Date?
    @Published var errorMessage: String?
    
    private var backgroundTaskTimer: Timer?
    private var authenticationService: AuthenticationService?
    private var cancellables = Set<AnyCancellable>()
    
    // Background task configuration
    private let backgroundCheckInterval: TimeInterval = 300 // 5 minutes
    private let maxBackgroundDuration: TimeInterval = 1800 // 30 minutes
    
    override init() {
        super.init()
        setupBackgroundTaskMonitoring()
    }
    
    /// Set the authentication service for background checks
    func setAuthenticationService(_ service: AuthenticationService) {
        self.authenticationService = service
    }
    
    // MARK: - Background Task Management
    
    /// Start background authentication monitoring
    func startBackgroundMonitoring() {
        guard !isBackgroundTaskActive else { return }
        
        print("🔄 Starting background authentication monitoring")
        isBackgroundTaskActive = true
        backgroundTaskStatus = .monitoring
        
        // Start periodic background checks
        startBackgroundTaskTimer()
        
        // Schedule background task with WatchKit
        scheduleBackgroundTask()
    }
    
    /// Stop background authentication monitoring
    func stopBackgroundMonitoring() {
        guard isBackgroundTaskActive else { return }
        
        print("⏹️ Stopping background authentication monitoring")
        isBackgroundTaskActive = false
        backgroundTaskStatus = .idle
        
        // Stop timer
        backgroundTaskTimer?.invalidate()
        backgroundTaskTimer = nil
        
        // Cancel background task
        cancelBackgroundTask()
    }
    
    // MARK: - Background Task Timer
    
    private func startBackgroundTaskTimer() {
        backgroundTaskTimer = Timer.scheduledTimer(withTimeInterval: backgroundCheckInterval, repeats: true) { [weak self] _ in
            self?.performBackgroundAuthenticationCheck()
        }
    }
    
    private func performBackgroundAuthenticationCheck() {
        guard let authService = authenticationService else {
            print("⚠️ No authentication service available for background check")
            return
        }
        
        print("🔍 Performing background authentication check")
        backgroundTaskStatus = .checking
        lastBackgroundCheck = Date()
        
        // Check if background authentication is due
        if authService.isBackgroundAuthenticationDue() {
            let result = authService.performBackgroundAuthentication()
            
            DispatchQueue.main.async {
                switch result {
                case .approved:
                    self.backgroundTaskStatus = .authenticated
                    print("✅ Background authentication successful")
                case .denied:
                    self.backgroundTaskStatus = .failed
                    print("❌ Background authentication failed")
                case .retry:
                    self.backgroundTaskStatus = .retry
                    print("🔄 Background authentication requires retry")
                case .error:
                    self.backgroundTaskStatus = .error
                    print("⚠️ Background authentication error")
                case .pending:
                    self.backgroundTaskStatus = .monitoring
                    print("⏳ Background authentication pending")
                }
            }
        } else {
            backgroundTaskStatus = .monitoring
            print("ℹ️ Background authentication not due yet")
        }
    }
    
    // MARK: - WatchKit Background Tasks
    
    private func scheduleBackgroundTask() {
        // Schedule background refresh task using correct WatchKit API
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(backgroundCheckInterval),
            userInfo: nil
        ) { error in
            // The system has scheduled the task or returned an error
            if let error = error {
                print("⚠️ Failed to schedule background refresh: \(error.localizedDescription)")
            }
            self.handleBackgroundRefresh()
        }
    }
    
    private func cancelBackgroundTask() {
        // WatchKit does not provide an API to cancel scheduled background refresh tasks.
        // You can choose to schedule a new refresh far in the future if needed.
    }
    
    private func handleBackgroundRefresh() {
        print("🔄 Handling background refresh")
        performBackgroundAuthenticationCheck()
        
        // Schedule next background refresh using correct API
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(backgroundCheckInterval),
            userInfo: nil
        ) { error in
            if let error = error {
                print("⚠️ Failed to schedule next background refresh: \(error.localizedDescription)")
            }
            self.handleBackgroundRefresh()
        }
    }
    
    // MARK: - Background Task Monitoring Setup
    
    private func setupBackgroundTaskMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: .init("AppDidEnterBackground"))
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .init("AppWillEnterForeground"))
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppDidEnterBackground() {
        print("📱 App entered background")
        
        // Continue background monitoring if it was active
        if isBackgroundTaskActive {
            backgroundTaskStatus = .background
        }
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 App will enter foreground")
        
        // Resume foreground monitoring
        if isBackgroundTaskActive {
            backgroundTaskStatus = .monitoring
        }
    }
    
    // MARK: - Data Cleanup
    
    private func cleanupExpiredData() {
        // Clean up old authentication attempts
        // This would be implemented based on your data retention policy
        print("🧹 Cleaning up expired data")
    }
    
    // MARK: - Status Information
    
    /// Get current background task status description
    var statusDescription: String {
        switch backgroundTaskStatus {
        case .idle:
            return "Background monitoring inactive"
        case .monitoring:
            return "Monitoring authentication status"
        case .checking:
            return "Performing background check"
        case .authenticated:
            return "Background authentication successful"
        case .failed:
            return "Background authentication failed"
        case .retry:
            return "Background authentication requires retry"
        case .error:
            return "Background authentication error"
        case .background:
            return "Running in background"
        }
    }
    
    /// Get time since last background check
    var timeSinceLastCheck: String {
        guard let lastCheck = lastBackgroundCheck else {
            return "Never"
        }
        
        let interval = Date().timeIntervalSince(lastCheck)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Background Task Status

enum BackgroundTaskStatus: String, CaseIterable {
    case idle = "idle"
    case monitoring = "monitoring"
    case checking = "checking"
    case authenticated = "authenticated"
    case failed = "failed"
    case retry = "retry"
    case error = "error"
    case background = "background"
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .monitoring: return "Monitoring"
        case .checking: return "Checking"
        case .authenticated: return "Authenticated"
        case .failed: return "Failed"
        case .retry: return "Retry Required"
        case .error: return "Error"
        case .background: return "Background"
        }
    }
    
    var color: String {
        switch self {
        case .idle: return "gray"
        case .monitoring: return "blue"
        case .checking: return "orange"
        case .authenticated: return "green"
        case .failed: return "red"
        case .retry: return "yellow"
        case .error: return "red"
        case .background: return "purple"
        }
    }
}
#endif

