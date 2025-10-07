//
//  WatchConnectivityService+Watch.swift
//  CardiacID_Watch_App
//
//  Watch-specific implementation of WatchConnectivityService
//

import Foundation
import WatchConnectivity
import Combine
import HealthKit

// MARK: - Watch-specific WatchConnectivityService Extension
extension WatchConnectivityService {
    
    // MARK: - Watch-specific Methods
    
    func sendHeartRateUpdate(_ heartRate: Int) {
        let message: [String: Any] = [
            WatchMessage.Keys.messageType: WatchMessage.heartRateUpdate.rawValue,
            WatchMessage.Keys.heartRate: heartRate,
            WatchMessage.Keys.timestamp: Date().timeIntervalSince1970
        ]
        
        sendMessage(
            message,
            replyHandler: { reply in
                print("Heart rate sent successfully: \(reply)")
            },
            errorHandler: { error in
                print("Error sending heart rate: \(error.localizedDescription)")
                self.errorSubject.send("Failed to send heart rate: \(error.localizedDescription)")
            }
        )
    }
    
    func sendAuthStatusUpdate(_ status: String) {
        let message: [String: Any] = [
            WatchMessage.Keys.messageType: WatchMessage.authStatusUpdate.rawValue,
            WatchMessage.Keys.authStatus: status
        ]
        
        sendMessage(
            message,
            replyHandler: { reply in
                print("Auth status sent successfully: \(reply)")
            },
            errorHandler: { error in
                print("Error sending auth status: \(error.localizedDescription)")
                self.errorSubject.send("Failed to send auth status: \(error.localizedDescription)")
            }
        )
    }
    
    func sendEnrollmentComplete(status: String) {
        let message: [String: Any] = [
            WatchMessage.Keys.messageType: WatchMessage.enrollmentComplete.rawValue,
            WatchMessage.Keys.enrollmentStatus: status
        ]
        
        sendMessage(
            message,
            replyHandler: { reply in
                print("Enrollment status sent successfully: \(reply)")
            },
            errorHandler: { error in
                print("Error sending enrollment status: \(error.localizedDescription)")
                self.errorSubject.send("Failed to send enrollment status: \(error.localizedDescription)")
            }
        )
    }
    
    // MARK: - Watch-specific Delegate Methods
    // Note: watchOS uses different delegate methods than iOS
    
    func sessionDidBecomeActive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivated = true
            self.isReachable = session.isReachable
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivated = false
        }
    }
}

// MARK: - Watch HealthKit Integration

class WatchHealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var currentHeartRate: Int = 0
    @Published var isAuthorized = false
    
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [heartRateType])
            await MainActor.run {
                isAuthorized = true
            }
        } catch {
            print("HealthKit authorization error: \(error)")
        }
    }
    
    func startHeartRateMonitoring() {
        guard isAuthorized else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKQuantitySample]) {
        guard let latestSample = samples.last else { return }
        
        let heartRate = Int(latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
        
        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
            // Send to iOS app
            WatchConnectivityService.shared.sendHeartRateUpdate(heartRate)
        }
    }
}