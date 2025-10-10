//
//  ErrorReporting.swift
//  HeartID Watch App
//
//  Comprehensive error tracking and reporting system
//

import Foundation
import os.log

/// Comprehensive error tracking and reporting system
class ErrorReportingService: ObservableObject {
    static let shared = ErrorReportingService()
    
    private let logger = Logger(subsystem: "com.heartid.watch", category: "ErrorReporting")
    private var errorLog: [ErrorReport] = []
    private let maxLogSize = 1000
    
    // MARK: - Error Categories
    
    enum ErrorCategory: String, CaseIterable, Codable {
        case authentication = "Authentication"
        case enrollment = "Enrollment"
        case healthKit = "HealthKit"
        case biometric = "Biometric"
        case security = "Security"
        case performance = "Performance"
        case network = "Network"
        case storage = "Storage"
        case ui = "UI"
        case system = "System"
        
        var severity: ErrorSeverity {
            switch self {
            case .authentication, .enrollment, .biometric, .security:
                return .high
            case .healthKit, .storage:
                return .medium
            case .performance, .network, .ui, .system:
                return .low
            }
        }
    }
    
    enum ErrorSeverity: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var priority: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    // MARK: - Error Report Model
    
    struct ErrorReport: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let category: ErrorCategory
        let severity: ErrorSeverity
        let message: String
        let details: String?
        let stackTrace: String?
        let userInfo: [String: String]?
        let deviceInfo: DeviceInfo
        
        init(category: ErrorCategory, severity: ErrorSeverity, message: String, details: String? = nil, error: Error? = nil) {
            self.id = UUID()
            self.timestamp = Date()
            self.category = category
            self.severity = severity
            self.message = message
            self.details = details
            self.stackTrace = error?.localizedDescription
            self.userInfo = nil
            self.deviceInfo = DeviceInfo.current
        }
    }
    
    struct DeviceInfo: Codable {
        let model: String
        let systemVersion: String
        let appVersion: String
        let watchOSVersion: String
        let availableStorage: Int64
        let batteryLevel: Float?
        
        static var current: DeviceInfo {
            return DeviceInfo(
                model: "Apple Watch",
                systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                watchOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                availableStorage: 0, // Would need to implement storage check
                batteryLevel: nil // Would need to implement battery check
            )
        }
    }
    
    // MARK: - Error Reporting Methods
    
    /// Report an error with automatic severity detection
    func reportError(category: ErrorCategory, message: String, details: String? = nil, error: Error? = nil) {
        let severity = determineSeverity(category: category, error: error)
        let report = ErrorReport(category: category, severity: severity, message: message, details: details, error: error)
        
        addErrorReport(report)
        logError(report)
        
        // Send to analytics if enabled
        if AppConfiguration.isAnalyticsEnabled {
            sendToAnalytics(report)
        }
    }
    
    /// Report a critical error that requires immediate attention
    func reportCriticalError(category: ErrorCategory, message: String, details: String? = nil, error: Error? = nil) {
        let report = ErrorReport(category: category, severity: .critical, message: message, details: details, error: error)
        
        addErrorReport(report)
        logError(report)
        
        // Always send critical errors
        sendToAnalytics(report)
        
        // Could trigger emergency protocols here
        handleCriticalError(report)
    }
    
    /// Report performance metrics
    func reportPerformanceMetric(operation: String, duration: TimeInterval, success: Bool, details: [String: Any]? = nil) {
        let message = "\(operation) completed in \(String(format: "%.3f", duration))s - \(success ? "Success" : "Failed")"
        let detailsString = details?.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        
        reportError(
            category: .performance,
            message: message,
            details: detailsString
        )
    }
    
    /// Report authentication attempt
    func reportAuthenticationAttempt(success: Bool, confidence: Double, duration: TimeInterval, retryCount: Int) {
        let message = "Authentication \(success ? "succeeded" : "failed") with \(String(format: "%.2f", confidence)) confidence"
        let details = "Duration: \(String(format: "%.3f", duration))s, Retries: \(retryCount)"
        
        reportError(
            category: .authentication,
            message: message,
            details: details
        )
    }
    
    /// Report enrollment attempt
    func reportEnrollmentAttempt(success: Bool, quality: Double, duration: TimeInterval, sampleCount: Int) {
        let message = "Enrollment \(success ? "succeeded" : "failed") with \(String(format: "%.2f", quality)) quality"
        let details = "Duration: \(String(format: "%.3f", duration))s, Samples: \(sampleCount)"
        
        reportError(
            category: .enrollment,
            message: message,
            details: details
        )
    }
    
    // MARK: - Private Methods
    
    private func determineSeverity(category: ErrorCategory, error: Error?) -> ErrorSeverity {
        let baseSeverity = category.severity
        
        // Upgrade severity based on error type
        if let error = error {
            if error is SecurityError {
                return .critical
            } else if error is DataCorruptionError {
                return .high
            } else if error is NetworkError {
                return .medium
            }
        }
        
        return baseSeverity
    }
    
    private func addErrorReport(_ report: ErrorReport) {
        errorLog.append(report)
        
        // Maintain log size
        if errorLog.count > maxLogSize {
            errorLog.removeFirst(errorLog.count - maxLogSize)
        }
    }
    
    private func logError(_ report: ErrorReport) {
        let logMessage = "[\(report.category.rawValue)] \(report.message)"
        
        switch report.severity {
        case .low:
            logger.info("\(logMessage)")
        case .medium:
            logger.warning("\(logMessage)")
        case .high:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
    }
    
    private func sendToAnalytics(_ report: ErrorReport) {
        // In a real implementation, this would send to analytics service
        // For now, we'll just log it
        logger.info("Analytics: \(report.category.rawValue) - \(report.message)")
    }
    
    private func handleCriticalError(_ report: ErrorReport) {
        // Handle critical errors - could trigger alerts, disable features, etc.
        logger.critical("Critical error detected: \(report.message)")
        
        // Could post notification for UI to handle
        NotificationCenter.default.post(
            name: .init("CriticalErrorDetected"),
            object: nil,
            userInfo: ["report": report]
        )
    }
    
    // MARK: - Public Access Methods
    
    /// Get all error reports
    func getAllErrors() -> [ErrorReport] {
        return errorLog
    }
    
    /// Get errors by category
    func getErrors(for category: ErrorCategory) -> [ErrorReport] {
        return errorLog.filter { $0.category == category }
    }
    
    /// Get errors by severity
    func getErrors(for severity: ErrorSeverity) -> [ErrorReport] {
        return errorLog.filter { $0.severity == severity }
    }
    
    /// Get recent errors (last 24 hours)
    func getRecentErrors() -> [ErrorReport] {
        let oneDayAgo = Date().addingTimeInterval(-86400)
        return errorLog.filter { $0.timestamp >= oneDayAgo }
    }
    
    /// Get error statistics
    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorLog.count
        let errorsByCategory = Dictionary(grouping: errorLog, by: { $0.category })
        let errorsBySeverity = Dictionary(grouping: errorLog, by: { $0.severity })
        
        return ErrorStatistics(
            totalErrors: totalErrors,
            errorsByCategory: errorsByCategory.mapValues { $0.count },
            errorsBySeverity: errorsBySeverity.mapValues { $0.count },
            recentErrors: getRecentErrors().count
        )
    }
    
    /// Clear error log
    func clearErrorLog() {
        errorLog.removeAll()
    }
    
    /// Export error log for debugging
    func exportErrorLog() -> Data? {
        return try? JSONEncoder().encode(errorLog)
    }
}

// MARK: - Error Statistics

struct ErrorStatistics {
    let totalErrors: Int
    let errorsByCategory: [ErrorReportingService.ErrorCategory: Int]
    let errorsBySeverity: [ErrorReportingService.ErrorSeverity: Int]
    let recentErrors: Int
    
    var summary: String {
        return """
        Total Errors: \(totalErrors)
        Recent (24h): \(recentErrors)
        Critical: \(errorsBySeverity[.critical] ?? 0)
        High: \(errorsBySeverity[.high] ?? 0)
        Medium: \(errorsBySeverity[.medium] ?? 0)
        Low: \(errorsBySeverity[.low] ?? 0)
        """
    }
}

// MARK: - Custom Error Types

enum SecurityError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case templateCorrupted
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt biometric template"
        case .decryptionFailed:
            return "Failed to decrypt biometric template"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .templateCorrupted:
            return "Biometric template is corrupted"
        }
    }
}

enum DataCorruptionError: Error, LocalizedError {
    case invalidData
    case checksumMismatch
    case versionMismatch
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Data format is invalid"
        case .checksumMismatch:
            return "Data integrity check failed"
        case .versionMismatch:
            return "Data version is incompatible"
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case connectionFailed
    case timeout
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Network connection failed"
        case .timeout:
            return "Network request timed out"
        case .serverError:
            return "Server returned an error"
        }
    }
}

// MARK: - Performance Monitoring

extension ErrorReportingService {
    
    /// Monitor performance of a block of code
    func monitorPerformance<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = Date()
        var success = true
        var error: Error?
        
        do {
            let result = try block()
            success = true
            let duration = Date().timeIntervalSince(startTime)
            reportPerformanceMetric(operation: operation, duration: duration, success: success)
            return result
        } catch let e {
            success = false
            error = e
            let duration = Date().timeIntervalSince(startTime)
            reportPerformanceMetric(operation: operation, duration: duration, success: success)
            
            if let error = error {
                reportError(category: .performance, message: "\(operation) failed", error: error)
            }
            throw e
        }
    }
    
    /// Monitor async performance of a block of code
    func monitorAsyncPerformance<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        var success = true
        var error: Error?
        
        do {
            let result = try await block()
            success = true
            let duration = Date().timeIntervalSince(startTime)
            reportPerformanceMetric(operation: operation, duration: duration, success: success)
            return result
        } catch let e {
            success = false
            error = e
            let duration = Date().timeIntervalSince(startTime)
            reportPerformanceMetric(operation: operation, duration: duration, success: success)
            
            if let error = error {
                reportError(category: .performance, message: "\(operation) failed", error: error)
            }
            throw e
        }
    }
}
