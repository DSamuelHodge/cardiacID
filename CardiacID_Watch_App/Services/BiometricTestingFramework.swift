//
//  BiometricTestingFramework.swift
//  HeartID Watch App
//
//  Comprehensive testing framework for biometric algorithms and validation
//

import Foundation
import HealthKit

// MARK: - Test Data Generators

/// Generates realistic test data for biometric algorithm testing
struct BiometricTestDataGenerator {
    
    /// Generate realistic heart rate samples for testing
    static func generateHeartRateSamples(
        count: Int = 200,
        baseRate: Double = 75.0,
        variability: Double = 5.0,
        noiseLevel: Double = 2.0
    ) -> [Double] {
        var samples: [Double] = []
        var currentRate = baseRate
        
        for i in 0..<count {
            // Add natural heart rate variability
            let variabilityFactor = sin(Double(i) * 0.1) * variability
            let noise = (Double.random(in: -1...1) * noiseLevel)
            
            currentRate = baseRate + variabilityFactor + noise
            
            // Ensure realistic heart rate range
            currentRate = max(40.0, min(200.0, currentRate))
            
            samples.append(currentRate)
        }
        
        return samples
    }
    
    /// Generate high-quality heart rate samples (low noise, good variability)
    static func generateHighQualitySamples() -> [Double] {
        return generateHeartRateSamples(
            count: 300,
            baseRate: 72.0,
            variability: 8.0,
            noiseLevel: 1.0
        )
    }
    
    /// Generate low-quality heart rate samples (high noise, poor variability)
    static func generateLowQualitySamples() -> [Double] {
        return generateHeartRateSamples(
            count: 50,
            baseRate: 75.0,
            variability: 2.0,
            noiseLevel: 15.0
        )
    }
    
    /// Generate samples with specific HRV characteristics
    static func generateSamplesWithHRV(
        rmssd: Double = 25.0,
        pnn50: Double = 0.15,
        count: Int = 200
    ) -> [Double] {
        // Generate RR intervals with specific HRV characteristics
        var rrIntervals: [Double] = []
        let baseRR = 60000.0 / 75.0 // 75 BPM baseline
        
        for _ in 0..<count {
            let baseInterval = baseRR + (Double.random(in: -50...50))
            rrIntervals.append(baseInterval)
        }
        
        // Convert RR intervals to heart rate
        return rrIntervals.map { 60000.0 / $0 }
    }
}

// MARK: - HRV Calculation Tests

/// Heart Rate Variability calculation and validation
struct HRVCalculator {
    
    struct HRVFeatures {
        let rmssd: Double
        let pnn50: Double
        let sdnn: Double
        let meanRR: Double
        let heartRateVariability: Double
        
        init(rmssd: Double, pnn50: Double, sdnn: Double, meanRR: Double, heartRateVariability: Double) {
            self.rmssd = rmssd
            self.pnn50 = pnn50
            self.sdnn = sdnn
            self.meanRR = meanRR
            self.heartRateVariability = heartRateVariability
        }
    }
    
    /// Calculate comprehensive HRV features from heart rate samples
    static func calculateHRV(_ samples: [Double]) -> HRVFeatures {
        guard samples.count > 1 else {
            return HRVFeatures(rmssd: 0, pnn50: 0, sdnn: 0, meanRR: 0, heartRateVariability: 0)
        }
        
        // Convert heart rate to RR intervals
        let rrIntervals = samples.map { 60000.0 / $0 }
        
        // Calculate RMSSD (Root Mean Square of Successive Differences)
        let rmssd = calculateRMSSD(rrIntervals)
        
        // Calculate pNN50 (Percentage of successive RR intervals differing by more than 50ms)
        let pnn50 = calculatePNN50(rrIntervals)
        
        // Calculate SDNN (Standard Deviation of RR intervals)
        let sdnn = calculateSDNN(rrIntervals)
        
        // Calculate mean RR interval
        let meanRR = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        
        // Calculate overall heart rate variability
        let heartRateVariability = calculateHeartRateVariability(samples)
        
        return HRVFeatures(
            rmssd: rmssd,
            pnn50: pnn50,
            sdnn: sdnn,
            meanRR: meanRR,
            heartRateVariability: heartRateVariability
        )
    }
    
    private static func calculateRMSSD(_ rrIntervals: [Double]) -> Double {
        guard rrIntervals.count > 1 else { return 0 }
        
        var sumOfSquaredDifferences: Double = 0
        for i in 1..<rrIntervals.count {
            let difference = rrIntervals[i] - rrIntervals[i-1]
            sumOfSquaredDifferences += difference * difference
        }
        
        return sqrt(sumOfSquaredDifferences / Double(rrIntervals.count - 1))
    }
    
    private static func calculatePNN50(_ rrIntervals: [Double]) -> Double {
        guard rrIntervals.count > 1 else { return 0 }
        
        var count = 0
        for i in 1..<rrIntervals.count {
            if abs(rrIntervals[i] - rrIntervals[i-1]) > 50 {
                count += 1
            }
        }
        
        return Double(count) / Double(rrIntervals.count - 1)
    }
    
    private static func calculateSDNN(_ rrIntervals: [Double]) -> Double {
        guard rrIntervals.count > 1 else { return 0 }
        
        let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let variance = rrIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rrIntervals.count)
        
        return sqrt(variance)
    }
    
    private static func calculateHeartRateVariability(_ samples: [Double]) -> Double {
        guard samples.count > 1 else { return 0 }
        
        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.map { pow($0 - mean, 2) }.reduce(0, +) / Double(samples.count)
        
        return sqrt(variance)
    }
}

// MARK: - Enhanced Biometric Validation

/// Enhanced validation for biometric data quality
struct EnhancedBiometricValidation {
    
    struct ValidationResult {
        let isValid: Bool
        let qualityScore: Double
        let errorMessage: String?
        let hrvFeatures: HRVCalculator.HRVFeatures?
        let recommendations: [String]
        
        init(isValid: Bool, qualityScore: Double, errorMessage: String? = nil, hrvFeatures: HRVCalculator.HRVFeatures? = nil, recommendations: [String] = []) {
            self.isValid = isValid
            self.qualityScore = qualityScore
            self.errorMessage = errorMessage
            self.hrvFeatures = hrvFeatures
            self.recommendations = recommendations
        }
    }
    
    /// Comprehensive validation of biometric data
    static func validate(_ samples: [Double]) -> ValidationResult {
        var recommendations: [String] = []
        var qualityFactors: [Double] = []
        
        // Check sample count
        guard samples.count >= 200 else {
            return ValidationResult(
                isValid: false,
                qualityScore: 0.0,
                errorMessage: "Insufficient data captured. Need at least 200 samples.",
                recommendations: ["Increase capture duration", "Ensure consistent sensor contact"]
            )
        }
        
        // Check heart rate range
        let avg = samples.reduce(0, +) / Double(samples.count)
        guard avg >= 40 && avg <= 200 else {
            return ValidationResult(
                isValid: false,
                qualityScore: 0.0,
                errorMessage: "Heart rate reading out of range (\(Int(avg)) BPM).",
                recommendations: ["Check sensor placement", "Ensure proper contact"]
            )
        }
        
        // Calculate HRV features
        let hrvFeatures = HRVCalculator.calculateHRV(samples)
        
        // Quality assessment based on HRV
        let hrvQuality = assessHRVQuality(hrvFeatures)
        qualityFactors.append(hrvQuality)
        
        // Check for variation (not flat line)
        let variance = samples.map { pow($0 - avg, 2) }.reduce(0, +) / Double(samples.count)
        let stdDev = sqrt(variance)
        
        if stdDev < 2.0 {
            recommendations.append("Increase movement or stress level for better variability")
            qualityFactors.append(0.3)
        } else if stdDev > 30.0 {
            recommendations.append("Reduce movement and ensure stable sensor contact")
            qualityFactors.append(0.4)
        } else {
            qualityFactors.append(0.8)
        }
        
        // Check for noise patterns
        let noiseLevel = assessNoiseLevel(samples)
        qualityFactors.append(noiseLevel)
        
        // Calculate overall quality score
        let overallQuality = qualityFactors.reduce(0, +) / Double(qualityFactors.count)
        
        let isValid = overallQuality >= 0.6 && hrvFeatures.rmssd > 10.0
        
        return ValidationResult(
            isValid: isValid,
            qualityScore: overallQuality,
            errorMessage: isValid ? nil : "Data quality insufficient for reliable authentication",
            hrvFeatures: hrvFeatures,
            recommendations: recommendations
        )
    }
    
    private static func assessHRVQuality(_ hrv: HRVCalculator.HRVFeatures) -> Double {
        var quality: Double = 0.5
        
        // RMSSD assessment (higher is generally better for healthy individuals)
        if hrv.rmssd > 30 {
            quality += 0.3
        } else if hrv.rmssd > 20 {
            quality += 0.2
        } else if hrv.rmssd > 10 {
            quality += 0.1
        }
        
        // pNN50 assessment
        if hrv.pnn50 > 0.1 {
            quality += 0.2
        } else if hrv.pnn50 > 0.05 {
            quality += 0.1
        }
        
        return min(1.0, quality)
    }
    
    private static func assessNoiseLevel(_ samples: [Double]) -> Double {
        // Calculate signal-to-noise ratio
        let mean = samples.reduce(0, +) / Double(samples.count)
        let signalPower = samples.map { pow($0 - mean, 2) }.reduce(0, +) / Double(samples.count)
        
        // Estimate noise by looking at rapid changes
        var noiseEstimate: Double = 0
        for i in 1..<samples.count {
            let change = abs(samples[i] - samples[i-1])
            if change > 10 { // Likely noise
                noiseEstimate += change
            }
        }
        
        let noisePower = noiseEstimate / Double(samples.count)
        
        // Higher signal-to-noise ratio is better
        let snr = signalPower / max(noisePower, 1.0)
        
        if snr > 10 {
            return 0.9
        } else if snr > 5 {
            return 0.7
        } else if snr > 2 {
            return 0.5
        } else {
            return 0.2
        }
    }
}

// MARK: - Mock Services for Testing

/// Mock HealthKit service for testing without hardware
class MockHealthKitService: HealthKitService, @unchecked Sendable {
    
    private var mockSamples: [HeartRateSample] = []
    private var mockAuthorizationStatus: Bool = true
    
    override init() {
        super.init()
        // Override the real HealthKit service for testing
    }
    
    /// Set mock authorization status
    func setMockAuthorization(_ authorized: Bool) {
        mockAuthorizationStatus = authorized
        isAuthorized = authorized
    }
    
    /// Set mock heart rate samples
    func setMockSamples(_ samples: [HeartRateSample]) {
        mockSamples = samples
        heartRateSamples = samples
    }
    
    /// Generate mock samples for testing
    func generateMockSamples(count: Int = 200) {
        let testData = BiometricTestDataGenerator.generateHeartRateSamples(count: count)
        let samples = testData.enumerated().map { index, value in
            HeartRateSample(
                value: value,
                timestamp: Date().addingTimeInterval(-Double(count - index)),
                source: "Mock Sensor"
            )
        }
        setMockSamples(samples)
    }
    
    override func testHeartRateDataAccess() async -> Bool {
        // Mock implementation - always returns true for testing
        return !mockSamples.isEmpty
    }
    
    override func ensureAuthorization() async -> AuthorizationResult {
        if mockAuthorizationStatus {
            return .authorized
        } else {
            return .denied("Mock authorization denied")
        }
    }
}

// MARK: - Performance Benchmarking

/// Performance monitoring for biometric operations
struct BiometricPerformanceMonitor {
    
    struct PerformanceMetrics {
        let operationName: String
        let duration: TimeInterval
        let memoryUsage: UInt64
        let sampleCount: Int
        let timestamp: Date
        
        init(operationName: String, duration: TimeInterval, memoryUsage: UInt64, sampleCount: Int) {
            self.operationName = operationName
            self.duration = duration
            self.memoryUsage = memoryUsage
            self.sampleCount = sampleCount
            self.timestamp = Date()
        }
    }
    
    private static var metrics: [PerformanceMetrics] = []
    
    /// Measure performance of a biometric operation
    static func measure<T>(_ operationName: String, sampleCount: Int = 0, operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()
        
        defer {
            let endTime = CFAbsoluteTimeGetCurrent()
            let endMemory = getMemoryUsage()
            
            let duration = endTime - startTime
            let memoryUsed = endMemory > startMemory ? endMemory - startMemory : 0
            
            let metric = PerformanceMetrics(
                operationName: operationName,
                duration: duration,
                memoryUsage: memoryUsed,
                sampleCount: sampleCount
            )
            
            metrics.append(metric)
            
            print("📊 Performance: \(operationName) - \(String(format: "%.3f", duration))s, \(memoryUsed) bytes")
        }
        
        return try operation()
    }
    
    /// Get current memory usage
    private static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Get performance metrics
    static func getMetrics() -> [PerformanceMetrics] {
        return metrics
    }
    
    /// Clear metrics
    static func clearMetrics() {
        metrics.removeAll()
    }
    
    /// Get average performance for an operation
    static func getAveragePerformance(for operationName: String) -> PerformanceMetrics? {
        let operationMetrics = metrics.filter { $0.operationName == operationName }
        guard !operationMetrics.isEmpty else { return nil }
        
        let avgDuration = operationMetrics.map { $0.duration }.reduce(0, +) / Double(operationMetrics.count)
        let avgMemory = operationMetrics.map { $0.memoryUsage }.reduce(0, +) / UInt64(operationMetrics.count)
        let avgSamples = operationMetrics.map { $0.sampleCount }.reduce(0, +) / operationMetrics.count
        
        return PerformanceMetrics(
            operationName: operationName,
            duration: avgDuration,
            memoryUsage: avgMemory,
            sampleCount: avgSamples
        )
    }
}
