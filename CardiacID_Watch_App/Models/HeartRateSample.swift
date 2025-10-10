//
//  HeartRateSample.swift
//  HeartID Watch App
//
//  Heart rate sample model for HealthKit integration
//

import Foundation
import HealthKit

/// Represents a single heart rate measurement
struct HeartRateSample: Codable, Identifiable {
    let id: UUID
    let value: Double // Heart rate in BPM
    let timestamp: Date
    let source: String
    let quality: Double // Data quality score (0.0 to 1.0)
    
    init(value: Double, timestamp: Date = Date(), source: String = "Apple Watch", quality: Double = 1.0) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
        self.source = source
        self.quality = quality
    }
    
    /// Create HeartRateSample from HealthKit HKQuantitySample
    init(from hkSample: HKQuantitySample) {
        self.id = UUID()
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        self.value = hkSample.quantity.doubleValue(for: heartRateUnit)
        self.timestamp = hkSample.startDate
        self.source = hkSample.sourceRevision.source.name
        self.quality = 1.0 // HealthKit samples are considered high quality
    }
    
    /// Validate if the heart rate value is within reasonable range
    var isValid: Bool {
        return value >= 30 && value <= 200
    }
    
    /// Get formatted heart rate string
    var formattedValue: String {
        return String(format: "%.0f BPM", value)
    }
    
    /// Get time since measurement
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
    
    /// Check if this sample is recent (within last 5 minutes)
    var isRecent: Bool {
        return Date().timeIntervalSince(timestamp) < 300 // 5 minutes
    }
    
    /// Get quality description
    var qualityDescription: String {
        switch quality {
        case 0.9...1.0:
            return "Excellent"
        case 0.7..<0.9:
            return "Good"
        case 0.5..<0.7:
            return "Fair"
        case 0.3..<0.5:
            return "Poor"
        default:
            return "Very Poor"
        }
    }
    
    /// Get source description
    var sourceDescription: String {
        switch source.lowercased() {
        case "apple watch":
            return "Apple Watch"
        case "iphone":
            return "iPhone"
        case "ecg":
            return "ECG"
        default:
            return source
        }
    }
}

// MARK: - Heart Rate Sample Collection

/// Collection of heart rate samples with analysis capabilities
struct HeartRateSampleCollection: Codable {
    let samples: [HeartRateSample]
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    init(samples: [HeartRateSample]) {
        self.samples = samples.sorted { $0.timestamp < $1.timestamp }
        self.startTime = self.samples.first?.timestamp ?? Date()
        self.endTime = self.samples.last?.timestamp ?? Date()
        self.duration = endTime.timeIntervalSince(startTime)
    }
    
    /// Calculate average heart rate
    var averageHeartRate: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map { $0.value }.reduce(0, +) / Double(samples.count)
    }
    
    /// Calculate heart rate variability (HRV)
    var heartRateVariability: Double {
        guard samples.count > 1 else { return 0 }
        
        let values = samples.map { $0.value }
        var differences: [Double] = []
        
        for i in 1..<values.count {
            differences.append(abs(values[i] - values[i-1]))
        }
        
        return differences.reduce(0, +) / Double(differences.count)
    }
    
    /// Get minimum heart rate
    var minHeartRate: Double {
        return samples.map { $0.value }.min() ?? 0
    }
    
    /// Get maximum heart rate
    var maxHeartRate: Double {
        return samples.map { $0.value }.max() ?? 0
    }
    
    /// Calculate data quality score
    var qualityScore: Double {
        guard !samples.isEmpty else { return 0 }
        
        let validSamples = samples.filter { $0.isValid }
        let validityRatio = Double(validSamples.count) / Double(samples.count)
        
        let avgQuality = samples.map { $0.quality }.reduce(0, +) / Double(samples.count)
        
        return validityRatio * avgQuality
    }
    
    /// Check if collection has sufficient data for analysis
    var hasSufficientData: Bool {
        return samples.count >= 10 && duration >= 5.0
    }
    
    /// Get samples within a specific time range
    func samples(in range: ClosedRange<Date>) -> [HeartRateSample] {
        return samples.filter { range.contains($0.timestamp) }
    }
    
    /// Get samples from the last N seconds
    func recentSamples(seconds: TimeInterval) -> [HeartRateSample] {
        let cutoffTime = Date().addingTimeInterval(-seconds)
        return samples.filter { $0.timestamp >= cutoffTime }
    }
    
    /// Get samples with quality above threshold
    func highQualitySamples(threshold: Double = 0.7) -> [HeartRateSample] {
        return samples.filter { $0.quality >= threshold }
    }
    
    /// Calculate trend direction (-1: decreasing, 0: stable, 1: increasing)
    var trendDirection: Int {
        guard samples.count >= 3 else { return 0 }
        
        let firstThird = Array(samples.prefix(samples.count / 3))
        let lastThird = Array(samples.suffix(samples.count / 3))
        
        let firstAvg = firstThird.map { $0.value }.reduce(0, +) / Double(firstThird.count)
        let lastAvg = lastThird.map { $0.value }.reduce(0, +) / Double(lastThird.count)
        
        let difference = lastAvg - firstAvg
        
        if difference > 5 {
            return 1 // Increasing
        } else if difference < -5 {
            return -1 // Decreasing
        } else {
            return 0 // Stable
        }
    }
    
    /// Get trend description
    var trendDescription: String {
        switch trendDirection {
        case 1:
            return "Increasing"
        case -1:
            return "Decreasing"
        default:
            return "Stable"
        }
    }
    
    /// Calculate data consistency score (0.0 to 1.0)
    var consistencyScore: Double {
        guard samples.count > 1 else { return 1.0 }
        
        let values = samples.map { $0.value }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        // Lower standard deviation = higher consistency
        let maxExpectedStdDev: Double = 15.0
        return max(0.0, 1.0 - (stdDev / maxExpectedStdDev))
    }
    
    /// Check if collection meets minimum requirements for analysis
    func meetsMinimumRequirements(for securityLevel: SecurityLevel) -> Bool {
        return samples.count >= securityLevel.minimumSamples && 
               duration >= securityLevel.recommendedCaptureDuration &&
               qualityScore >= 0.7
    }
}

// MARK: - Heart Rate Analysis

/// Analysis result for heart rate pattern
struct HeartRateAnalysis: Codable {
    let collection: HeartRateSampleCollection
    let averageHeartRate: Double
    let heartRateVariability: Double
    let qualityScore: Double
    let patternStability: Double
    let analysisTimestamp: Date
    
    init(from collection: HeartRateSampleCollection) {
        self.collection = collection
        self.averageHeartRate = collection.averageHeartRate
        self.heartRateVariability = collection.heartRateVariability
        self.qualityScore = collection.qualityScore
        self.analysisTimestamp = Date()
        
        // Calculate pattern stability (lower HRV = more stable)
        let maxHRV: Double = 20.0 // Maximum expected HRV
        self.patternStability = max(0, 1.0 - (collection.heartRateVariability / maxHRV))
    }
    
    /// Check if analysis meets quality requirements
    var meetsQualityRequirements: Bool {
        return qualityScore >= 0.7 && patternStability >= 0.5
    }
    
    /// Get analysis summary
    var summary: String {
        return """
        Average HR: \(String(format: "%.0f", averageHeartRate)) BPM
        HRV: \(String(format: "%.1f", heartRateVariability))
        Quality: \(String(format: "%.0f%%", qualityScore * 100))
        Stability: \(String(format: "%.0f%%", patternStability * 100))
        """
    }
}
