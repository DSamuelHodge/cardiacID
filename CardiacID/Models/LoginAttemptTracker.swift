import Foundation

/// Tracks login attempts and implements progressive lockout periods
class LoginAttemptTracker: ObservableObject {
    @Published var remainingAttempts: Int
    @Published var isLockedOut: Bool = false
    @Published var lockoutEndTime: Date?
    @Published var lockoutReason: String?
    
    private let userDefaults = UserDefaults.standard
    private let maxAttemptsPerPeriod = 2
    
    // Progressive lockout periods (in minutes)
    private let lockoutPeriods: [TimeInterval] = [
        10,    // 10 minutes
        20,    // 20 minutes  
        40,    // 40 minutes
        90,    // 90 minutes
        360,   // 6 hours
        1440,  // 1 day
        2880   // 48 hours (and continues with 48-hour increments)
    ]
    
    private var currentPeriodIndex: Int = 0
    private var attemptsInCurrentPeriod: Int = 0
    private var lastAttemptTime: Date?
    
    init() {
        self.remainingAttempts = maxAttemptsPerPeriod
        loadState()
        checkLockoutStatus()
    }
    
    // MARK: - Public Methods
    
    /// Record a failed login attempt
    func recordFailedAttempt() {
        attemptsInCurrentPeriod += 1
        remainingAttempts = max(0, maxAttemptsPerPeriod - attemptsInCurrentPeriod)
        lastAttemptTime = Date()
        
        // If we've used all attempts in this period, move to next lockout period
        if attemptsInCurrentPeriod >= maxAttemptsPerPeriod {
            currentPeriodIndex = min(currentPeriodIndex + 1, lockoutPeriods.count - 1)
            attemptsInCurrentPeriod = 0
            remainingAttempts = maxAttemptsPerPeriod
            
            // Set lockout
            let lockoutDuration = lockoutPeriods[currentPeriodIndex]
            lockoutEndTime = Date().addingTimeInterval(lockoutDuration * 60) // Convert to seconds
            isLockedOut = true
            lockoutReason = getLockoutReason(for: currentPeriodIndex)
        }
        
        saveState()
    }
    
    /// Record a successful login attempt
    func recordSuccessfulAttempt() {
        // Reset everything on successful login
        currentPeriodIndex = 0
        attemptsInCurrentPeriod = 0
        remainingAttempts = maxAttemptsPerPeriod
        isLockedOut = false
        lockoutEndTime = nil
        lockoutReason = nil
        lastAttemptTime = nil
        
        saveState()
    }
    
    /// Check if user can attempt login
    func canAttemptLogin() -> Bool {
        checkLockoutStatus()
        return !isLockedOut
    }
    
    /// Get time remaining in lockout
    func getTimeRemainingInLockout() -> TimeInterval? {
        guard let lockoutEndTime = lockoutEndTime else { return nil }
        let remaining = lockoutEndTime.timeIntervalSinceNow
        
        // Check for NaN or Infinity values
        guard remaining.isFinite else { return 0 }
        
        return remaining > 0 ? remaining : 0
    }
    
    /// Get formatted time remaining string
    func getFormattedTimeRemaining() -> String? {
        guard let timeRemaining = getTimeRemainingInLockout() else { return nil }
        
        // Ensure we have a valid positive time remaining and check for NaN/Infinity
        guard timeRemaining > 0 && timeRemaining.isFinite else { return "0s" }
        
        // Use safe integer conversion to avoid NaN
        let totalSeconds = Int(timeRemaining.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Reset all lockout state (for testing/debugging)
    func resetLockoutState() {
        currentPeriodIndex = 0
        attemptsInCurrentPeriod = 0
        remainingAttempts = maxAttemptsPerPeriod
        isLockedOut = false
        lockoutEndTime = nil
        lockoutReason = nil
        lastAttemptTime = nil
        
        saveState()
        print("🔓 LoginAttemptTracker: Lockout state reset")
    }
    
    // MARK: - Private Methods
    
    private func checkLockoutStatus() {
        guard let lockoutEndTime = lockoutEndTime else {
            isLockedOut = false
            return
        }
        
        let now = Date()
        if now >= lockoutEndTime {
            // Lockout period has expired
            isLockedOut = false
            self.lockoutEndTime = nil
            lockoutReason = nil
            saveState()
        } else {
            isLockedOut = true
        }
    }
    
    private func getLockoutReason(for periodIndex: Int) -> String {
        let periods = [
            "10 minutes",
            "20 minutes", 
            "40 minutes",
            "90 minutes",
            "6 hours",
            "1 day",
            "48 hours"
        ]
        
        if periodIndex < periods.count {
            return "Account locked for \(periods[periodIndex])"
        } else {
            let additionalDays = (periodIndex - 6) * 2
            return "Account locked for \(48 + additionalDays) hours"
        }
    }
    
    private func saveState() {
        userDefaults.set(currentPeriodIndex, forKey: "loginPeriodIndex")
        userDefaults.set(attemptsInCurrentPeriod, forKey: "loginAttemptsInPeriod")
        userDefaults.set(remainingAttempts, forKey: "loginRemainingAttempts")
        userDefaults.set(isLockedOut, forKey: "loginIsLockedOut")
        userDefaults.set(lockoutEndTime, forKey: "loginLockoutEndTime")
        userDefaults.set(lockoutReason, forKey: "loginLockoutReason")
        userDefaults.set(lastAttemptTime, forKey: "loginLastAttemptTime")
    }
    
    private func loadState() {
        currentPeriodIndex = userDefaults.integer(forKey: "loginPeriodIndex")
        attemptsInCurrentPeriod = userDefaults.integer(forKey: "loginAttemptsInPeriod")
        remainingAttempts = userDefaults.integer(forKey: "loginRemainingAttempts")
        isLockedOut = userDefaults.bool(forKey: "loginIsLockedOut")
        lockoutEndTime = userDefaults.object(forKey: "loginLockoutEndTime") as? Date
        lockoutReason = userDefaults.string(forKey: "loginLockoutReason")
        lastAttemptTime = userDefaults.object(forKey: "loginLastAttemptTime") as? Date
        
        // Ensure remaining attempts is valid
        if remainingAttempts < 0 {
            remainingAttempts = 0
        }
    }
}

// MARK: - Lockout Settings

struct LockoutSettings: Codable {
    var isEnabled: Bool = true
    var maxAttemptsPerPeriod: Int = 2
    var lockoutPeriods: [TimeInterval] = [
        10,    // 10 minutes
        20,    // 20 minutes  
        40,    // 40 minutes
        90,    // 90 minutes
        360,   // 6 hours
        1440,  // 1 day
        2880   // 48 hours
    ]
    var customPeriods: [TimeInterval] = []
    var useCustomPeriods: Bool = false
    
    var effectivePeriods: [TimeInterval] {
        return useCustomPeriods ? customPeriods : lockoutPeriods
    }
}
