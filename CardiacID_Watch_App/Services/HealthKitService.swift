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
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            errorMessage = "HealthKit not available"
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        isAuthorized = (status == .sharingAuthorized)
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit not available"
            return false
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            checkAuthorizationStatus()
            return true
        } catch {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
            return false
        }
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
        let startDate = Date().addingTimeInterval(-duration)
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: HKQuery.predicateForSamples(withStart: startDate, end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            Task { @MainActor in
                if let error = error {
                    self?.isCapturing = false
                    self?.errorMessage = error.localizedDescription
                    completion([], error)
                } else if let samples = samples as? [HKQuantitySample] {
                    let heartRateSamples = samples.map { sample in
                        HeartRateSample(
                            value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                            timestamp: sample.startDate,
                            source: sample.sourceRevision.source.name
                        )
                    }
                    self?.heartRateSamples = heartRateSamples
                    completion(heartRateSamples, nil)
                }
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
        
        // Update progress
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.captureProgress = min(1.0, self.captureProgress + 0.1)
            }
        }
        
        // Stop capture after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.stopHeartRateCapture()
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
        var heartRateSamples: [Double] = []
        
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
        
        if heartRateSamples.isEmpty {
            return .failure(HealthKitError.noDataCaptured)
        }
        
        return .success(heartRateSamples)
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