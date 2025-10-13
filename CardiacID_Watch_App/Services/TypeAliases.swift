//
//  TypeAliases.swift  
//  HeartID Watch App
//
//  🧹 CLEANED UP - Resolved type conflicts and removed unnecessary aliases
//  🎯 FOCUSED ON - Essential debug logging and watchOS compatibility
//

import Foundation
import SwiftUI

// MARK: - Debug Logger Implementation

/// Centralized debug logger for consistent logging throughout the app
/// Follows the singleton pattern as specified in architectural guidelines
class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] \(message)")
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    // Domain-specific convenience methods
    func auth(_ message: String) {
        log("🔐 AUTH: \(message)", level: .info)
    }
    
    func health(_ message: String) {
        log("❤️ HEALTH: \(message)", level: .info)
    }
    
    func data(_ message: String) {
        log("💾 DATA: \(message)", level: .info)
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Global Debug Logger Access
/// Global debug logger instance for consistent logging throughout the app
/// This enables clean logging syntax: debugLog.info("message")
let debugLog = DebugLogger.shared

// MARK: - WatchOS Design Constants

/// WatchOS-optimized color palette for consistent UI design
enum WatchColors {
    static let backgroundGray = Color.gray.opacity(0.2)
    static let cardBackground = Color.black.opacity(0.3)
    static let secondaryBackground = Color.gray.opacity(0.1)
    static let primary = Color.blue
    static let secondary = Color.gray
    static let accent = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}

/// WatchOS-optimized spacing and sizing constants
enum WatchMetrics {
    static let cornerRadius: CGFloat = 12
    static let smallPadding: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    
    // Button dimensions optimized for watch screens
    static let buttonHeight: CGFloat = 44
    static let minTouchTarget: CGFloat = 44
    
    // Animation durations
    static let shortAnimation: Double = 0.3
    static let standardAnimation: Double = 0.5
    static let longAnimation: Double = 0.8
}