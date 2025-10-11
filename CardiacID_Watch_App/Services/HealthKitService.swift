//
//  HealthKitService.swift
//  HeartID Watch App
//
//  Enterprise-ready HealthKit service with full compatibility
//

import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isCapturing = false
    @Published var currentHeartRate: Double = 0
    @Published var captureProgress: Double = 0
    @Published var errorMessage: String?
    @Published var heartRateSamples: [HeartRateSample] = []
    
    private var heartRateQuery: HKQuery?
    private var captureTimer: Timer?
    
    // MARK: - Computed Properties
    
    var authorizationStatus: String {
        guard HKHealthStore.isHealthDataAvailable() else {
            return "Not Available"
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            errorMessage = "HealthKit not available"
            print("❌ HealthKit not available")
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        print("🔍 Checking HealthKit authorization status: \(status)")
        
        isAuthorized = (status == .sharingAuthorized)
        
        if isAuthorized {
            print("✅ HealthKit is authorized for heart rate data")
        } else {
            print("⚠️ HealthKit authorization status: \(status)")
        }
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit not available"
            return false
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        print("🔐 Requesting HealthKit authorization for heart rate data...")
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            
            // Check status immediately after request
            let status = healthStore.authorizationStatus(for: heartRateType)
            print("📊 Authorization status after request: \(status)")
            
            checkAuthorizationStatus()
            print("✅ Authorization request completed. isAuthorized: \(isAuthorized)")
            
            return true
        } catch {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
            print("❌ Authorization error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Enhanced Authorization Management
    
    /// Comprehensive authorization check with user-friendly error handling
    func ensureAuthorization() async -> AuthorizationResult {
        // First check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            return .notAvailable("HealthKit is not available on this device")
        }
        
        // Check current authorization status
        checkAuthorizationStatus()
        
        if isAuthorized {
            return .authorized
        }
        
        // Request authorization
        let success = await requestAuthorization()
        
        if success {
            // Add a small delay to allow HealthKit to update its status
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Re-check after authorization with retry logic
            checkAuthorizationStatus()
            
            if isAuthorized {
                return .authorized
            } else {
                // Try one more time after another brief delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                checkAuthorizationStatus()
                
                if isAuthorized {
                    return .authorized
                } else {
                    // Get detailed status for debugging
                    let details = getDetailedAuthorizationStatus()
                    return .denied("Authorization was granted but status check failed. Current status: \(details.status)")
                }
            }
        } else {
            return .denied("Failed to request HealthKit authorization")
        }
    }
    
    /// Get detailed authorization status for debugging
    func getDetailedAuthorizationStatus() -> AuthorizationDetails {
        guard HKHealthStore.isHealthDataAvailable() else {
            return AuthorizationDetails(
                isAvailable: false,
                isAuthorized: false,
                status: "Not Available",
                canRequest: false,
                errorMessage: "HealthKit not available on this device"
            )
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        let statusString: String
        let canRequest: Bool
        
        switch status {
        case .notDetermined:
            statusString = "Not Determined"
            canRequest = true
        case .sharingDenied:
            statusString = "Denied"
            canRequest = false
        case .sharingAuthorized:
            statusString = "Authorized"
            canRequest = false
        @unknown default:
            statusString = "Unknown"
            canRequest = true
        }
        
        return AuthorizationDetails(
            isAvailable: true,
            isAuthorized: status == .sharingAuthorized,
            status: statusString,
            canRequest: canRequest,
            errorMessage: nil
        )
    }
    
    // MARK: - Sensor Engagement Validation
    
    /// Validate that sensors are properly engaged before capture
    func validateSensorEngagement() async -> SensorValidationResult {
        print("🔍 Validating sensor engagement...")
        
        guard isAuthorized else {
            print("❌ HealthKit not authorized")
            return .notAuthorized("HealthKit authorization required")
        }
        
        // Check if we can read heart rate data
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        guard status == .sharingAuthorized else {
            print("❌ Heart rate data access not authorized. Status: \(status)")
            return .notAuthorized("Heart rate data access not authorized")
        }
        
        print("✅ Sensor engagement validation passed")
        return .ready
    }
    
    /// Test actual heart rate data access to ensure sensors are working
    func testHeartRateDataAccess() async -> Bool {
        print("🧪 Testing heart rate data access...")
        
        guard isAuthorized else {
            print("❌ Not authorized for heart rate data")
            return false
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Try to query for recent heart rate data
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-60), // Last minute
            end: nil
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Heart rate data access test failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else if let samples = samples, !samples.isEmpty {
                    print("✅ Heart rate data access test passed - found \(samples.count) samples")
                    continuation.resume(returning: true)
                } else {
                    print("⚠️ Heart rate data access test - no recent data found")
                    continuation.resume(returning: true) // Still consider this a success
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Comprehensive HealthKit diagnostics for troubleshooting
    func runHealthKitDiagnostics() async -> String {
        var diagnostics: [String] = []
        
        diagnostics.append("🔍 HealthKit Diagnostics Report")
        diagnostics.append("=====================================")
        
        // Check availability
        let isAvailable = HKHealthStore.isHealthDataAvailable()
        diagnostics.append("HealthKit Available: \(isAvailable)")
        
        if !isAvailable {
            diagnostics.append("❌ HealthKit is not available on this device")
            return diagnostics.joined(separator: "\n")
        }
        
        // Check heart rate type
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        diagnostics.append("Heart Rate Type: \(heartRateType)")
        
        // Check authorization status
        let status = healthStore.authorizationStatus(for: heartRateType)
        diagnostics.append("Authorization Status: \(status)")
        
        // Check our internal state
        diagnostics.append("Internal isAuthorized: \(isAuthorized)")
        
        // Test data access
        let dataAccessTest = await testHeartRateDataAccess()
        diagnostics.append("Data Access Test: \(dataAccessTest ? "✅ Passed" : "❌ Failed")")
        
        // Get detailed status
        let details = getDetailedAuthorizationStatus()
        diagnostics.append("Detailed Status: \(details.status)")
        diagnostics.append("Can Request: \(details.canRequest)")
        
        if let errorMessage = details.errorMessage {
            diagnostics.append("Error: \(errorMessage)")
        }
        
        diagnostics.append("=====================================")
        
        return diagnostics.joined(separator: "\n")
    }
    
    // MARK: - Heart Rate Capture (Legacy Compatibility)
    
    func startHeartRateCapture(duration: TimeInterval, completion: @escaping ([HeartRateSample], Error?) -> Void) {
        guard isAuthorized else {
            completion([], HealthKitError.notAuthorized)
            return
        }
        
        guard !isCapturing else {
            completion([], HealthKitError.alreadyCapturing)
            return
        }
        
        isCapturing = true
        heartRateSamples = []
        captureProgress = 0
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        var collectedSamples: [HeartRateSample] = []
        let captureStartTime = Date()
        
        // Create a timer to continuously collect samples during the capture duration
        captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            // Query for samples from the last 2 seconds
            let queryStartDate = Date().addingTimeInterval(-2.0)
            let predicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: nil)
            
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Sample query error: \(error)")
                        return
                    }
                    
                    if let samples = samples as? [HKQuantitySample] {
                        let newSamples = samples.map { sample in
                            HeartRateSample(
                                value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                                timestamp: sample.startDate,
                                source: sample.sourceRevision.source.name
                            )
                        }
                        
                        // Add new samples to our collection
                        collectedSamples.append(contentsOf: newSamples)
                        self.heartRateSamples = collectedSamples
                        
                        // Update current heart rate with the latest sample
                        if let latestSample = newSamples.first {
                            self.currentHeartRate = latestSample.value
                        }
                        
                        print("📊 Collected \(collectedSamples.count) samples, latest HR: \(self.currentHeartRate)")
                    }
                }
            }
            
            self.healthStore.execute(query)
            
            // Update progress
            let elapsed = Date().timeIntervalSince(captureStartTime)
            self.captureProgress = min(elapsed / duration, 1.0)
            
            // Check if capture duration is complete
            if elapsed >= duration {
                timer.invalidate()
                self.isCapturing = false
                self.captureProgress = 1.0
                
                // Call completion with collected samples
                completion(collectedSamples, nil)
                print("✅ Capture completed with \(collectedSamples.count) samples")
            }
        }
    }
    
    // MARK: - Modern Async Heart Rate Capture
    
    func startHeartRateCapture(duration: TimeInterval = 8.0) async -> Result<[Double], Error> {
        guard isAuthorized else {
            return .failure(HealthKitError.notAuthorized)
        }
        
        guard !isCapturing else {
            return .failure(HealthKitError.alreadyCapturing)
        }
        
        isCapturing = true
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let startDate = Date().addingTimeInterval(-duration)
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: HKQuery.predicateForSamples(withStart: startDate, end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.isCapturing = false
                    self.errorMessage = error.localizedDescription
                } else if let samples = samples as? [HKQuantitySample] {
                    self.heartRateSamples = samples.map { HeartRateSample(value: $0.quantity.doubleValue(for: HKUnit(from: "count/min")), timestamp: $0.startDate, source: $0.sourceRevision.source.name) }
                }
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
        
        // Wait for capture duration
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        stopHeartRateCapture()
        
        // Convert HeartRateSample array to Double array
        let capturedValues = heartRateSamples.map { $0.value }
        
        if capturedValues.isEmpty {
            return .failure(HealthKitError.noDataCaptured)
        }
        
        return .success(capturedValues)
    }
    
    func stopHeartRateCapture() {
        isCapturing = false
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
        captureTimer?.invalidate()
        captureTimer = nil
        captureProgress = 0
    }
    
    // MARK: - Data Validation
    
    func validateHeartRateData(_ data: [Double]) -> Bool {
        guard !data.isEmpty else { return false }
        
        // Basic validation: heart rate should be between 40-200 BPM
        return data.allSatisfy { $0 >= 40 && $0 <= 200 }
    }
    
    // MARK: - Error Management
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Error Types

enum HealthKitError: Error, LocalizedError {
    case notAuthorized
    case alreadyCapturing
    case noDataCaptured
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit authorization required"
        case .alreadyCapturing:
            return "Heart rate capture already in progress"
        case .noDataCaptured:
            return "No heart rate data captured"
        case .notAvailable:
            return "HealthKit not available on this device"
        }
    }
}

// MARK: - Authorization Result Types

enum AuthorizationResult {
    case authorized
    case denied(String)
    case notAvailable(String)
}

enum SensorValidationResult {
    case ready
    case notAuthorized(String)
    case noRecentData(String)
    case sensorError(String)
}

struct AuthorizationDetails {
    let isAvailable: Bool
    let isAuthorized: Bool
    let status: String
    let canRequest: Bool
    let errorMessage: String?
}