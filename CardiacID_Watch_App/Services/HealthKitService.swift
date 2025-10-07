import Foundation
import HealthKit
import Combine

/// Service for managing HealthKit integration and PPG sensor access
class HealthKitService: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    var heartRateSamples: [HeartRateSample] = []
    private var captureStartTime: Date?
    private var captureDuration: TimeInterval = AppConfiguration.defaultCaptureDuration
    
    @Published var isAuthorized = false
    @Published var isCapturing = false
    @Published var currentHeartRate: Double = 0
    @Published var captureProgress: Double = 0
    @Published var errorMessage: String?
    
    private var captureTimer: Timer?
    private var heartRateSubject = PassthroughSubject<[HeartRateSample], Never>()
    
    var heartRatePublisher: AnyPublisher<[HeartRateSample], Never> {
        heartRateSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        
        // Delay authorization check to allow HealthKit to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAuthorizationStatus()
        }
        
        print("🏥 HealthKitService initialized")
        print("📱 Device HealthKit availability: \(HKHealthStore.isHealthDataAvailable())")
    }
    
    /// Request HealthKit authorization with enhanced error handling
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            isAuthorized = false
            print("❌ HealthKit not available on this device")
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let ecgType = HKObjectType.electrocardiogramType()
        let typesToRead: Set<HKObjectType> = [heartRateType, ecgType]
        
        // Clear any previous error messages
        errorMessage = nil
        print("🔐 Requesting HealthKit authorization...")
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit authorization successful")
                    // Re-check authorization status after request
                    self?.checkAuthorizationStatus()
                } else {
                    self?.isAuthorized = false
                    let errorMsg = error?.localizedDescription ?? "Failed to authorize HealthKit access"
                    self?.errorMessage = errorMsg
                    print("❌ HealthKit authorization failed: \(errorMsg)")
                }
            }
        }
    }
    
    /// Check current authorization status
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        // Consider both sharingAuthorized and notDetermined as potentially authorized
        // notDetermined means we can still request authorization
        isAuthorized = (status == .sharingAuthorized || status == .notDetermined)
        
        if status == .sharingDenied {
            errorMessage = "HealthKit access denied. Please enable in Settings."
        } else if status == .notDetermined {
            // Don't show error for notDetermined, just request authorization
            errorMessage = nil
        }
    }
    
    /// Start capturing heart rate data for pattern analysis
    func startHeartRateCapture(duration: TimeInterval = AppConfiguration.defaultCaptureDuration) {
        guard isAuthorized else {
            errorMessage = "HealthKit authorization required"
            return
        }
        
        guard !isCapturing else {
            errorMessage = "Heart rate capture already in progress"
            return
        }
        
        // Validate duration
        guard duration >= AppConfiguration.minCaptureDuration && duration <= AppConfiguration.maxCaptureDuration else {
            errorMessage = "Invalid capture duration. Must be between 9-16 seconds"
            return
        }
        
        captureDuration = duration
        captureStartTime = Date()
        isCapturing = true
        heartRateSamples.removeAll()
        captureProgress = 0
        errorMessage = nil
        
        // Start real-time heart rate monitoring
        startRealTimeHeartRateQuery()
        
        // Set up capture timer
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCaptureProgress()
        }
    }
    
    /// Stop capturing heart rate data
    func stopHeartRateCapture() {
        isCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
        
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        // Process captured samples
        if !heartRateSamples.isEmpty {
            heartRateSubject.send(heartRateSamples)
        }
    }
    
    /// Start real-time heart rate query
    private func startRealTimeHeartRateQuery() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Heart rate query error: \(error.localizedDescription)"
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                let heartRateSamples = samples.map { HeartRateSample(from: $0) }
                self?.processHeartRateSamples(heartRateSamples)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Heart rate update error: \(error.localizedDescription)"
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                let heartRateSamples = samples.map { HeartRateSample(from: $0) }
                self?.processHeartRateSamples(heartRateSamples)
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
    }
    
    /// Process incoming heart rate samples
    private func processHeartRateSamples(_ samples: [HeartRateSample]) {
        guard isCapturing else { return }
        
        // Filter samples to only include those from the current capture session
        let currentSamples = samples.filter { sample in
            guard let startTime = captureStartTime else { return false }
            return sample.timestamp >= startTime
        }
        
        heartRateSamples.append(contentsOf: currentSamples)
        
        // Update current heart rate (most recent sample)
        if let latestSample = currentSamples.last {
            currentHeartRate = latestSample.value
        }
        
        // Check if capture duration is complete
        if let startTime = captureStartTime,
           Date().timeIntervalSince(startTime) >= captureDuration {
            stopHeartRateCapture()
        }
    }
    
    /// Update capture progress
    private func updateCaptureProgress() {
        guard let startTime = captureStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        captureProgress = min(elapsed / captureDuration, 1.0)
        
        if captureProgress >= 1.0 {
            stopHeartRateCapture()
        }
    }
    
    /// Get recent heart rate data for analysis
    func getRecentHeartRateData(limit: Int = 100) -> [HeartRateSample] {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to fetch heart rate data: \(error.localizedDescription)"
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else { return }
                let heartRateSamples = samples.map { HeartRateSample(from: $0) }
                self.heartRateSubject.send(heartRateSamples)
            }
        }
        
        healthStore.execute(query)
        return heartRateSamples
    }
    
    /// Validate heart rate data quality
    func validateHeartRateData(_ samples: [HeartRateSample]) -> Bool {
        guard samples.count >= AppConfiguration.minPatternSamples else {
            errorMessage = "Insufficient heart rate samples. Need at least \(AppConfiguration.minPatternSamples)"
            return false
        }
        
        // Check for reasonable heart rate values (30-200 BPM)
        let validSamples = samples.filter { sample in
            sample.value >= 30 && sample.value <= 200
        }
        
        guard validSamples.count >= AppConfiguration.minPatternSamples else {
            errorMessage = "Invalid heart rate values detected"
            return false
        }
        
        // Check for data consistency (not all the same value)
        let uniqueValues = Set(validSamples.map { $0.value })
        guard uniqueValues.count > 1 else {
            errorMessage = "Heart rate data appears static"
            return false
        }
        
        return true
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Check if ECG is available on this device
    func isECGAvailable() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        // Check if ECG is available (Apple Watch Series 4+)
        let ecgType = HKObjectType.electrocardiogramType()
        let status = healthStore.authorizationStatus(for: ecgType)
        return status != .notDetermined || status == .sharingAuthorized || status == .sharingDenied
    }
    
    /// Get detailed authorization status for debugging
    func getAuthorizationStatus() -> String {
        guard HKHealthStore.isHealthDataAvailable() else {
            return "HealthKit not available"
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        switch status {
        case .notDetermined:
            return "Not determined - can request authorization"
        case .sharingDenied:
            return "Sharing denied - user denied access"
        case .sharingAuthorized:
            return "Sharing authorized - ready to use"
        @unknown default:
            return "Unknown status"
        }
    }
    
    /// Check if alternative heart rate sources are available
    func getAlternativeHeartRateSources() -> [String] {
        var sources: [String] = []
        
        // Check for ECG availability
        if isECGAvailable() {
            sources.append("ECG (Apple Watch Series 4+)")
        }
        
        // Check for heart rate sensor
        if HKHealthStore.isHealthDataAvailable() {
            sources.append("Heart Rate Sensor")
        }
        
        // Could add more sources here in the future
        // sources.append("External Heart Rate Monitor")
        // sources.append("Camera-based Heart Rate")
        
        return sources
    }
    
    /// Get comprehensive system status for debugging
    func getSystemStatus() -> String {
        var status: [String] = []
        
        status.append("HealthKit Available: \(HKHealthStore.isHealthDataAvailable())")
        status.append("Authorization: \(getAuthorizationStatus())")
        status.append("ECG Available: \(isECGAvailable())")
        status.append("Alternative Sources: \(getAlternativeHeartRateSources().joined(separator: ", "))")
        
        return status.joined(separator: " | ")
    }
}

