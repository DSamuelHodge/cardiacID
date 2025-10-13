//
//  EnhancedBiometricValidation.swift
//  HeartID Watch App
//
//  Advanced biometric validation with comprehensive quality assessment
//

import Foundation
import Accelerate

/// Enhanced biometric validation system for enterprise security
struct EnhancedBiometricValidation {
    
    // MARK: - Configuration Constants
    
    private static let minimumSampleSize = 200
    private static let maximumSampleSize = 1000
    private static let minimumQualityScore = 0.7
    private static let heartRateRange: ClosedRange<Double> = 40...200
    private static let maxAllowedNoiseLevel = 25.0
    
    // MARK: - Validation Result
    
    struct ValidationResult {
        let isValid: Bool
        let qualityScore: Double
        let errorMessage: String?
        let recommendations: [String]
        let hrvFeatures: HRVFeatures?
        let validationDetails: ValidationDetails
        
        init(isValid: Bool, qualityScore: Double, errorMessage: String? = nil, 
             recommendations: [String] = [], hrvFeatures: HRVFeatures? = nil,
             validationDetails: ValidationDetails) {
            self.isValid = isValid
            self.qualityScore = qualityScore
            self.errorMessage = errorMessage
            self.recommendations = recommendations
            self.hrvFeatures = hrvFeatures
            self.validationDetails = validationDetails
        }
    }
    
    // MARK: - HRV Features Structure
    
    struct HRVFeatures {
        let rmssd: Double      // Root mean square of successive differences
        let pnn50: Double      // Percentage of NN intervals > 50ms
        let sdnn: Double       // Standard deviation of NN intervals
        let triangularIndex: Double  // HRV triangular index
        let meanHR: Double     // Mean heart rate
        let maxHR: Double      // Maximum heart rate
        let minHR: Double      // Minimum heart rate
        
        init(rmssd: Double, pnn50: Double, sdnn: Double, triangularIndex: Double, 
             meanHR: Double, maxHR: Double, minHR: Double) {
            self.rmssd = rmssd
            self.pnn50 = pnn50
            self.sdnn = sdnn
            self.triangularIndex = triangularIndex
            self.meanHR = meanHR
            self.maxHR = maxHR
            self.minHR = minHR
        }
    }
    
    // MARK: - HRV Calculation
    
    private static func calculateHRV(_ samples: [Double]) -> HRVFeatures {
        guard samples.count > 1 else {
            return HRVFeatures(rmssd: 0, pnn50: 0, sdnn: 0, triangularIndex: 0, 
                             meanHR: 0, maxHR: 0, minHR: 0)
        }
        
        // Calculate successive differences
        var successiveDifferences: [Double] = []
        for i in 1..<samples.count {
            successiveDifferences.append(abs(samples[i] - samples[i-1]))
        }
        
        // RMSSD (Root Mean Square of Successive Differences)
        let squaredDiffs = successiveDifferences.map { $0 * $0 }
        let rmssd = sqrt(squaredDiffs.reduce(0, +) / Double(squaredDiffs.count))
        
        // PNN50 (Percentage of successive differences > 50ms)
        let diffsOver50 = successiveDifferences.filter { $0 > 50.0 }.count
        let pnn50 = Double(diffsOver50) / Double(successiveDifferences.count) * 100.0
        
        // Basic statistics
        let meanHR = samples.reduce(0, +) / Double(samples.count)
        let maxHR = samples.max() ?? 0
        let minHR = samples.min() ?? 0
        
        // SDNN (Standard Deviation of NN intervals)
        let variance = samples.map { pow($0 - meanHR, 2) }.reduce(0, +) / Double(samples.count)
        let sdnn = sqrt(variance)
        
        // Simplified Triangular Index
        let range = maxHR - minHR
        let triangularIndex = range > 0 ? (maxHR - minHR) / meanHR : 0
        
        return HRVFeatures(
            rmssd: rmssd,
            pnn50: pnn50,
            sdnn: sdnn,
            triangularIndex: triangularIndex,
            meanHR: meanHR,
            maxHR: maxHR,
            minHR: minHR
        )
    }

    // MARK: - Validation Details Structure
    
    struct ValidationDetails {
        let sampleCount: Int
        let heartRateRange: (min: Double, max: Double)
        let averageHeartRate: Double
        let heartRateVariability: Double
        let signalNoiseRatio: Double
        let consistencyScore: Double
        let completenessScore: Double
        let stabilityScore: Double
    }
    
    // MARK: - Main Validation Method
    
    /// Comprehensive validation of biometric data
    static func validate(_ samples: [Double]) -> ValidationResult {
        print("🔍 Enhanced validation: Analyzing \(samples.count) samples")
        
        var recommendations: [String] = []
        var qualityComponents: [String: Double] = [:]
        
        // 1. Basic validation checks
        let basicValidation = performBasicValidation(samples)
        if !basicValidation.isValid {
            return ValidationResult(
                isValid: false,
                qualityScore: 0.0,
                errorMessage: basicValidation.errorMessage,
                recommendations: basicValidation.recommendations,
                validationDetails: createBasicDetails(samples)
            )
        }
        
        // 2. Sample size validation
        let sampleSizeScore = validateSampleSize(samples.count)
        qualityComponents["sampleSize"] = sampleSizeScore.score
        recommendations.append(contentsOf: sampleSizeScore.recommendations)
        
        // 3. Heart rate range validation
        let rangeValidation = validateHeartRateRange(samples)
        qualityComponents["range"] = rangeValidation.score
        recommendations.append(contentsOf: rangeValidation.recommendations)
        
        // 4. Signal quality assessment
        let signalQuality = assessSignalQuality(samples)
        qualityComponents["signalQuality"] = signalQuality.score
        recommendations.append(contentsOf: signalQuality.recommendations)
        
        // 5. Consistency analysis
        let consistency = analyzeConsistency(samples)
        qualityComponents["consistency"] = consistency.score
        recommendations.append(contentsOf: consistency.recommendations)
        
        // 6. HRV analysis
        let hrvFeatures = calculateHRV(samples)
        let hrvValidation = validateHRVFeatures(hrvFeatures)
        qualityComponents["hrv"] = hrvValidation.score
        recommendations.append(contentsOf: hrvValidation.recommendations)
        
        // 7. Completeness check
        let completeness = assessCompleteness(samples)
        qualityComponents["completeness"] = completeness.score
        recommendations.append(contentsOf: completeness.recommendations)
        
        // 8. Stability analysis
        let stability = analyzeStability(samples)
        qualityComponents["stability"] = stability.score
        recommendations.append(contentsOf: stability.recommendations)
        
        // Calculate weighted overall quality score
        let overallQuality = calculateWeightedQualityScore(qualityComponents)
        
        // Create detailed validation information
        let validationDetails = createValidationDetails(samples, qualityComponents)
        
        // Determine if validation passes
        let isValid = overallQuality >= minimumQualityScore
        let errorMessage = isValid ? nil : "Quality score below threshold (\(String(format: "%.1f%%", overallQuality * 100)) < \(String(format: "%.1f%%", minimumQualityScore * 100)))"
        
        // Remove duplicate recommendations
        let uniqueRecommendations = Array(Set(recommendations))
        
        print("✅ Enhanced validation complete - Quality: \(String(format: "%.1f%%", overallQuality * 100))")
        
        return ValidationResult(
            isValid: isValid,
            qualityScore: overallQuality,
            errorMessage: errorMessage,
            recommendations: uniqueRecommendations,
            hrvFeatures: hrvFeatures,
            validationDetails: validationDetails
        )
    }
    
    // MARK: - Basic Validation
    
    private static func performBasicValidation(_ samples: [Double]) -> (isValid: Bool, errorMessage: String?, recommendations: [String]) {
        // Check if samples exist
        guard !samples.isEmpty else {
            return (false, "No heart rate data captured", ["Ensure proper sensor contact"])
        }
        
        // Check minimum sample size
        guard samples.count >= 50 else {
            return (false, "Insufficient data captured (\(samples.count) samples)", ["Extend capture duration", "Ensure continuous sensor contact"])
        }
        
        // Check for all zero values
        if samples.allSatisfy({ $0 == 0 }) {
            return (false, "No heart rate signal detected", ["Check sensor placement", "Ensure skin contact", "Clean sensor"])
        }
        
        // Check for invalid values
        let invalidCount = samples.filter { !heartRateRange.contains($0) }.count
        if invalidCount > samples.count / 4 {  // Allow up to 25% invalid readings
            return (false, "Too many invalid heart rate readings", ["Improve sensor contact", "Reduce motion during capture"])
        }
        
        return (true, nil, [])
    }
    
    // MARK: - Sample Size Validation
    
    private static func validateSampleSize(_ count: Int) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        let score: Double
        
        if count < minimumSampleSize {
            score = Double(count) / Double(minimumSampleSize) * 0.6  // Max 60% for insufficient samples
            recommendations.append("Extend capture duration to \(minimumSampleSize) samples")
        } else if count > maximumSampleSize {
            score = 0.95  // Slightly penalize excessive samples
            recommendations.append("Optimize capture duration")
        } else {
            // Optimal range
            let optimal = Double(minimumSampleSize + maximumSampleSize) / 2
            let distance = abs(Double(count) - optimal) / optimal
            score = max(0.8, 1.0 - distance * 0.2)
        }
        
        return (score, recommendations)
    }
    
    // MARK: - Heart Rate Range Validation
    
    private static func validateHeartRateRange(_ samples: [Double]) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        
        let validSamples = samples.filter { heartRateRange.contains($0) }
        let validRatio = Double(validSamples.count) / Double(samples.count)
        
        if validRatio < 0.8 {
            recommendations.append("Improve sensor contact for stable readings")
        }
        
        // Check for reasonable heart rate statistics
        let average = validSamples.reduce(0, +) / Double(max(validSamples.count, 1))
        
        if average < 50 || average > 180 {
            recommendations.append("Unusual heart rate detected - ensure proper measurement conditions")
        }
        
        let score = validRatio * 0.8 + (average >= 50 && average <= 180 ? 0.2 : 0.0)
        
        return (score, recommendations)
    }
    
    // MARK: - Signal Quality Assessment
    
    private static func assessSignalQuality(_ samples: [Double]) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        
        // Calculate signal-to-noise ratio approximation
        let average = samples.reduce(0, +) / Double(samples.count)
        let deviations = samples.map { abs($0 - average) }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        
        // Noise level assessment
        let noiseLevel = averageDeviation
        let signalNoiseRatio = average / max(noiseLevel, 1.0)
        
        var score = 0.5  // Base score
        
        if noiseLevel <= 5.0 {
            score += 0.3  // Excellent signal quality
        } else if noiseLevel <= 10.0 {
            score += 0.2  // Good signal quality
            recommendations.append("Reduce movement during capture for better quality")
        } else if noiseLevel <= maxAllowedNoiseLevel {
            score += 0.1  // Acceptable signal quality
            recommendations.append("Hold steady during capture to reduce noise")
        } else {
            // Poor signal quality
            recommendations.append("Significant noise detected - ensure stable sensor contact")
        }
        
        // SNR bonus
        if signalNoiseRatio > 8.0 {
            score += 0.2
        } else if signalNoiseRatio > 5.0 {
            score += 0.1
        }
        
        return (min(1.0, score), recommendations)
    }
    
    // MARK: - Consistency Analysis
    
    private static func analyzeConsistency(_ samples: [Double]) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        
        // Analyze segments of the signal
        let segmentSize = max(20, samples.count / 10)
        var segmentAverages: [Double] = []
        
        for i in stride(from: 0, to: samples.count, by: segmentSize) {
            let endIndex = min(i + segmentSize, samples.count)
            let segment = Array(samples[i..<endIndex])
            let average = segment.reduce(0, +) / Double(segment.count)
            segmentAverages.append(average)
        }
        
        // Calculate consistency between segments
        let overallAverage = segmentAverages.reduce(0, +) / Double(segmentAverages.count)
        let segmentVariations = segmentAverages.map { abs($0 - overallAverage) }
        let averageVariation = segmentVariations.reduce(0, +) / Double(segmentVariations.count)
        
        // Score based on consistency
        let consistencyRatio = averageVariation / max(overallAverage, 1.0)
        
        var score: Double
        if consistencyRatio <= 0.05 {
            score = 1.0
        } else if consistencyRatio <= 0.1 {
            score = 0.9
        } else if consistencyRatio <= 0.2 {
            score = 0.7
            recommendations.append("Maintain steady position during capture")
        } else {
            score = 0.4
            recommendations.append("High variation detected - ensure consistent sensor contact")
        }
        
        return (score, recommendations)
    }
    
    // MARK: - HRV Features Validation
    
    private static func validateHRVFeatures(_ features: HRVFeatures) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        var score = 0.5  // Base score
        
        // RMSSD validation (healthy range: 20-100ms)
        if features.rmssd >= 20 && features.rmssd <= 100 {
            score += 0.2
        } else if features.rmssd < 10 {
            recommendations.append("Very low heart rate variability detected")
        }
        
        // pNN50 validation (healthy range: 0.05-0.5)
        if features.pnn50 >= 0.05 && features.pnn50 <= 0.5 {
            score += 0.15
        } else if features.pnn50 < 0.02 {
            recommendations.append("Low parasympathetic activity detected")
        }
        
        // Heart rate variability assessment
        if features.heartRateVariability >= 5 && features.heartRateVariability <= 50 {
            score += 0.15
        } else {
            recommendations.append("Unusual heart rate variability pattern")
        }
        
        // Overall HRV health check
        if features.rmssd > 0 && features.pnn50 > 0 {
            score += 0.1  // Basic HRV present
        }
        
        return (min(1.0, score), recommendations)
    }
    
    // MARK: - Completeness Assessment
    
    private static func assessCompleteness(_ samples: [Double]) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        
        // Check for gaps in data (consecutive zeros or identical values)
        let zeroCount = samples.filter { $0 == 0 }.count
        let zeroRatio = Double(zeroCount) / Double(samples.count)
        
        // Check for stuck values (same value repeated)
        let uniqueValues = Set(samples).count
        let uniqueRatio = Double(uniqueValues) / Double(samples.count)
        
        var score = 1.0
        
        // Penalize excessive zeros
        if zeroRatio > 0.1 {
            score -= zeroRatio * 0.5
            recommendations.append("Data gaps detected - ensure continuous sensor contact")
        }
        
        // Penalize lack of variation
        if uniqueRatio < 0.1 {
            score -= 0.4
            recommendations.append("Insufficient variation - check sensor placement")
        } else if uniqueRatio < 0.3 {
            score -= 0.2
            recommendations.append("Limited variation detected")
        }
        
        return (max(0.0, score), recommendations)
    }
    
    // MARK: - Stability Analysis
    
    private static func analyzeStability(_ samples: [Double]) -> (score: Double, recommendations: [String]) {
        var recommendations: [String] = []
        
        // Analyze rate of change
        let changes = zip(samples, samples.dropFirst()).map { abs($1 - $0) }
        let averageChange = changes.reduce(0, +) / Double(max(changes.count, 1))
        
        // Calculate stability score
        var score: Double
        
        if averageChange <= 2.0 {
            score = 1.0  // Very stable
        } else if averageChange <= 5.0 {
            score = 0.9  // Good stability
        } else if averageChange <= 10.0 {
            score = 0.7  // Moderate stability
            recommendations.append("Reduce movement for more stable readings")
        } else if averageChange <= 20.0 {
            score = 0.5  // Poor stability
            recommendations.append("Significant movement detected - hold steady")
        } else {
            score = 0.2  // Very unstable
            recommendations.append("Excessive movement - ensure stable sensor contact")
        }
        
        return (score, recommendations)
    }
    
    // MARK: - Quality Score Calculation
    
    private static func calculateWeightedQualityScore(_ components: [String: Double]) -> Double {
        // Weighted combination of quality components
        let weights: [String: Double] = [
            "sampleSize": 0.15,
            "range": 0.15,
            "signalQuality": 0.25,
            "consistency": 0.15,
            "hrv": 0.15,
            "completeness": 0.10,
            "stability": 0.05
        ]
        
        var weightedSum = 0.0
        var totalWeight = 0.0
        
        for (component, score) in components {
            if let weight = weights[component] {
                weightedSum += score * weight
                totalWeight += weight
            }
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }
    
    // MARK: - Validation Details Creation
    
    private static func createValidationDetails(_ samples: [Double], _ qualityComponents: [String: Double]) -> ValidationDetails {
        let minHR = samples.min() ?? 0
        let maxHR = samples.max() ?? 0
        let avgHR = samples.reduce(0, +) / Double(max(samples.count, 1))
        
        // Calculate HRV
        let hrv = calculateSimpleHRV(samples)
        
        // Calculate SNR approximation
        let deviations = samples.map { abs($0 - avgHR) }
        let avgDeviation = deviations.reduce(0, +) / Double(max(deviations.count, 1))
        let snr = avgHR / max(avgDeviation, 1.0)
        
        return ValidationDetails(
            sampleCount: samples.count,
            heartRateRange: (min: minHR, max: maxHR),
            averageHeartRate: avgHR,
            heartRateVariability: hrv,
            signalNoiseRatio: snr,
            consistencyScore: qualityComponents["consistency"] ?? 0.0,
            completenessScore: qualityComponents["completeness"] ?? 0.0,
            stabilityScore: qualityComponents["stability"] ?? 0.0
        )
    }
    
    private static func createBasicDetails(_ samples: [Double]) -> ValidationDetails {
        return ValidationDetails(
            sampleCount: samples.count,
            heartRateRange: (min: samples.min() ?? 0, max: samples.max() ?? 0),
            averageHeartRate: samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count),
            heartRateVariability: 0,
            signalNoiseRatio: 0,
            consistencyScore: 0,
            completenessScore: 0,
            stabilityScore: 0
        )
    }
    
    private static func calculateSimpleHRV(_ samples: [Double]) -> Double {
        guard samples.count > 1 else { return 0 }
        
        let differences = zip(samples, samples.dropFirst()).map { abs($1 - $0) }
        return differences.reduce(0, +) / Double(differences.count)
    }
}