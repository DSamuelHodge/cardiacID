import Foundation
import WatchConnectivity
import Combine

/// Service for handling communication between watchOS and iOS apps
class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var lastMessage: [String: Any]?
    @Published var connectionStatus: String = "Not Connected"
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
        setupNotificationObservers()
        print("⌚ WatchConnectivityService initialized")
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            connectionStatus = "Watch Connectivity Not Supported"
            print("❌ Watch Connectivity not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        print("📱 WatchConnectivity session activated")
    }
    
    private func setupNotificationObservers() {
        // Listen for enrollment status updates
        NotificationCenter.default.addObserver(
            forName: .init("SendEnrollmentStatus"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isEnrolled = notification.userInfo?["isEnrolled"] as? Bool {
                self?.sendEnrollmentStatus(isEnrolled) { success in
                    if success {
                        print("Enrollment status sent to iOS app successfully")
                    } else {
                        print("Failed to send enrollment status to iOS app")
                    }
                }
            }
        }
        
        // Listen for authentication result updates
        NotificationCenter.default.addObserver(
            forName: .init("SendAuthenticationResult"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let raw = userInfo["result"] as? String else { return }

            let message = userInfo["message"] as? String
            let confidence = userInfo["confidence"] as? Double

            let result: AuthenticationResult
            switch raw {
            case "approved":
                result = .approved(confidence: confidence ?? 1.0)
            case "denied":
                result = .denied(reason: message ?? "Denied")
            case "retry":
                result = .retry(message: message ?? "Please try again")
            case "error":
                result = .error(message: message ?? "Unknown error")
            default:
                // Unknown result type; treat as error for integrity
                result = .error(message: "Unknown result type: \(raw)")
            }

            self?.sendAuthenticationResult(result) { success in
                if success {
                    print("Authentication result sent to iOS app successfully")
                } else {
                    print("Failed to send authentication result to iOS app")
                }
            }
        }
    }
    // Note: AuthenticationResult(rawValue:) is not valid for associated-value enum.
    // Mapping to UserAuthStatus and metadata is handled via mapAuthenticationResult(_:)
    
    /// Send message to iOS companion app
    func sendMessage(_ message: [String: Any], completion: @escaping (Bool) -> Void = { _ in }) {
        guard let session = session, session.isReachable else {
            connectionStatus = "iOS App Not Reachable"
            completion(false)
            return
        }
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                self.lastMessage = response
                completion(true)
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.connectionStatus = "Error: \(error.localizedDescription)"
                completion(false)
            }
        })
    }
    
    /// Send heart pattern data to iOS app
    func sendHeartPatternData(_ heartPattern: [Double], completion: @escaping (Bool) -> Void = { _ in }) {
        let message: [String: Any] = [
            "type": "heartPattern",
            "data": heartPattern,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(message, completion: completion)
    }
    
    /// Map AuthenticationResult to a transport-friendly payload values
    private func mapAuthenticationResult(_ result: AuthenticationResult) -> (status: String, message: String?, confidence: Double?, isSuccessful: Bool) {
        switch result {
        case .approved(let confidence):
            return (status: "approved", message: nil, confidence: confidence, isSuccessful: true)
        case .denied(let reason):
            return (status: "denied", message: reason, confidence: nil, isSuccessful: false)
        case .retry(let message):
            // Represent retry as pending to reflect in-progress auth on iOS
            return (status: "pending", message: message, confidence: nil, isSuccessful: false)
        case .error(let message):
            return (status: "error", message: message, confidence: nil, isSuccessful: false)
        case .pending:
            return (status: "pending", message: "Authentication pending", confidence: nil, isSuccessful: false)
        }
    }
    
    /// Send authentication result to iOS app
    func sendAuthenticationResult(_ result: AuthenticationResult, completion: @escaping (Bool) -> Void = { _ in }) {
        // Map AuthenticationResult to UserAuthStatus and metadata
        let mapped = mapAuthenticationResult(result)
        var message: [String: Any] = [
            "type": "authenticationResult",
            "status": mapped.status, // UserAuthStatus raw value
            "timestamp": Date().timeIntervalSince1970,
            "isSuccessful": mapped.isSuccessful
        ]
        if let confidence = mapped.confidence { message["confidence"] = confidence }
        if let text = mapped.message { message["message"] = text }
        sendMessage(message, completion: completion)
    }
    
    /// Send enrollment status to iOS app
    func sendEnrollmentStatus(_ isEnrolled: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        let message: [String: Any] = [
            "type": "enrollmentStatus",
            "isEnrolled": isEnrolled,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(message, completion: completion)
    }
    
    /// Request data from iOS app
    func requestData(_ dataType: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let message: [String: Any] = [
            "type": "requestData",
            "dataType": dataType,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(message, completion: completion)
    }
    
    /// Get comprehensive connection status for debugging
    func getConnectionDiagnostics() -> String {
        var diagnostics: [String] = []
        
        diagnostics.append("WatchConnectivity Supported: \(WCSession.isSupported())")
        
        if let session = session {
            diagnostics.append("Session State: \(session.activationState.rawValue)")
            diagnostics.append("Is Reachable: \(session.isReachable)")
            // Note: isPaired and isWatchAppInstalled are not available on watchOS
        } else {
            diagnostics.append("Session: Not initialized")
        }
        
        diagnostics.append("Current Status: \(connectionStatus)")
        diagnostics.append("Last Message: \(lastMessage?.description ?? "None")")
        
        return diagnostics.joined(separator: " | ")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityServiceWatch: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("❌ WatchConnectivity activation error: \(error.localizedDescription)")
                self.connectionStatus = "Activation Error: \(error.localizedDescription)"
                self.isConnected = false
                return
            }
            
            switch activationState {
            case .activated:
                self.isConnected = session.isReachable
                self.connectionStatus = session.isReachable ? "Connected to iOS" : "iOS App Not Reachable"
                print("✅ WatchConnectivity activated - Reachable: \(session.isReachable)")
            case .inactive:
                self.isConnected = false
                self.connectionStatus = "Inactive"
                print("⚠️ WatchConnectivity inactive")
            case .notActivated:
                self.isConnected = false
                self.connectionStatus = "Not Activated"
                print("❌ WatchConnectivity not activated")
            @unknown default:
                self.isConnected = false
                self.connectionStatus = "Unknown State"
                print("❓ WatchConnectivity unknown state")
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            self.connectionStatus = session.isReachable ? "Connected to iOS" : "iOS App Not Reachable"
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.lastMessage = message
            self.handleReceivedMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.lastMessage = message
            self.handleReceivedMessage(message)
            
            // Send acknowledgment
            replyHandler(["status": "received"])
        }
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "heartPatternRequest":
            // iOS app is requesting heart pattern data
            // This would trigger the watch to start capturing heart data
            NotificationCenter.default.post(name: .heartPatternRequest, object: nil)
            
        case "authenticationRequest":
            // iOS app is requesting authentication
            NotificationCenter.default.post(name: .authenticationRequest, object: nil)
            
        case "enrollmentRequest":
            // iOS app is requesting enrollment
            NotificationCenter.default.post(name: .enrollmentRequest, object: nil)
            
        case "settingsUpdate":
            // iOS app is updating settings
            if let settings = message["settings"] as? [String: Any] {
                NotificationCenter.default.post(name: .settingsUpdate, object: settings)
            }
            
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let heartPatternRequest = Notification.Name("heartPatternRequest")
    static let authenticationRequest = Notification.Name("authenticationRequest")
    static let enrollmentRequest = Notification.Name("enrollmentRequest")
    static let settingsUpdate = Notification.Name("settingsUpdate")
}
