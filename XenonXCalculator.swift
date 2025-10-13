//
//  XenonXCalculator.swift
//  HeartID Watch App
//
//  Proprietary heart pattern analysis calculator for enhanced biometric authentication
//  Implements advanced signal processing algorithms for pattern recognition
//

import Foundation
import Accelerate

/// Advanced heart pattern analysis calculator using proprietary XenonX algorithms
class XenonXCalculator {
    
    // MARK: - Configuration Constants
    
    private struct Constants {
        static let minSampleCount = 100
        static let maxSampleCount = 1000
        static let baselineWindow = 20
        static let patternFeatureCount = 10
        static let fftSize = 256
    }
    
    // MARK: - Public Analysis Methods
    
    /// Analyze heart rate pattern and generate XenonX result
    func analyzePattern(_ heartRateData: [Double]) -> XenonXResult {
        debugLog.info("🧮 XenonX: Analyzing pattern with \(heartRateData.count) samples")
        
        // Validate input data
        guard heartRateData.count >= Constants.minSampleCount else {
            debugLog.warning("⚠️ XenonX: Insufficient data - need at least \(Constants.minSampleCount) samples")
            return createEmptyResult(reason: "Insufficient data")
        }
        
        // Preprocess the data
        let preprocessedData = preprocessHeartRateData(heartRateData)
        
        // Extract multiple feature vectors
        let features = extractAdvancedFeatures(from: preprocessedData)
        
        // Generate pattern ID based on feature fingerprint
        let patternId = generatePatternId(from: features)
        
        // Calculate confidence based on data quality and feature consistency
        let confidence = calculatePatternConfidence(features: features, originalData: heartRateData)
        
        // Create analysis data package
        let analysisData = packageAnalysisData(features: features, preprocessed: preprocessedData)
        
        debugLog.info("✅ XenonX: Pattern analysis complete - Confidence: \(String(format: "%.1f%%", confidence * 100))")
        
        return XenonXResult(
            patternId: patternId,
            confidence: confidence,
            analysisData: analysisData
        )
    }
    
    /// Compare two XenonX patterns and return similarity confidence
    func comparePatterns(_ pattern1: XenonXResult, _ pattern2: XenonXResult) -> Double {
        debugLog.info("🔍 XenonX: Comparing patterns \(pattern1.patternId) vs \(pattern2.patternId)")
        
        // Extract features from both patterns
        guard let features1 = extractFeaturesFromAnalysisData(pattern1.analysisData),
              let features2 = extractFeaturesFromAnalysisData(pattern2.analysisData) else {
            debugLog.error("❌ XenonX: Failed to extract features for comparison")
            return 0.0
        }
        
        // Multi-dimensional feature comparison
        let similarities = [
            compareFrequencyFeatures(features1.frequency, features2.frequency),
            compareTimeFeatures(features1.time, features2.time),
            compareStatisticalFeatures(features1.statistical, features2.statistical),
            compareVariabilityFeatures(features1.variability, features2.variability)
        ]
        
        // Weighted confidence calculation
        let weights = [0.3, 0.25, 0.25, 0.2] // Frequency domain gets highest weight
        let weightedSimilarity = zip(similarities, weights)
            .map { $0.0 * $0.1 }
            .reduce(0, +)
        
        // Apply temporal stability factor
        let temporalFactor = calculateTemporalStability(pattern1, pattern2)
        let finalConfidence = weightedSimilarity * temporalFactor
        
        debugLog.info("📊 XenonX: Pattern similarity = \(String(format: "%.1f%%", finalConfidence * 100))")
        
        return finalConfidence
    }
    
    // MARK: - Data Preprocessing
    
    private func preprocessHeartRateData(_ data: [Double]) -> [Double] {
        // Remove outliers using interquartile range method
        let sortedData = data.sorted()
        let q1Index = sortedData.count / 4
        let q3Index = 3 * sortedData.count / 4
        let q1 = sortedData[q1Index]
        let q3 = sortedData[q3Index]
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        // Filter outliers
        let filteredData = data.filter { $0 >= lowerBound && $0 <= upperBound }
        
        // Apply smoothing filter
        return applySmoothingFilter(filteredData)
    }
    
    private func applySmoothingFilter(_ data: [Double]) -> [Double] {
        let windowSize = 5
        var smoothedData: [Double] = []
        
        for i in 0..<data.count {
            let startIndex = max(0, i - windowSize/2)
            let endIndex = min(data.count, i + windowSize/2 + 1)
            let window = Array(data[startIndex..<endIndex])
            let average = window.reduce(0, +) / Double(window.count)
            smoothedData.append(average)
        }
        
        return smoothedData
    }
    
    // MARK: - Feature Extraction
    
    private func extractAdvancedFeatures(from data: [Double]) -> PatternFeatures {
        return PatternFeatures(
            frequency: extractFrequencyFeatures(data),
            time: extractTimeFeatures(data),
            statistical: extractStatisticalFeatures(data),
            variability: extractVariabilityFeatures(data)
        )
    }
    
    private func extractFrequencyFeatures(_ data: [Double]) -> FrequencyFeatures {
        // Perform FFT analysis
        let fftResult = performFFT(data)
        
        return FrequencyFeatures(
            dominantFrequency: findDominantFrequency(fftResult),
            spectralCentroid: calculateSpectralCentroid(fftResult),
            spectralSpread: calculateSpectralSpread(fftResult),
            spectralRolloff: calculateSpectralRolloff(fftResult)
        )
    }
    
    private func extractTimeFeatures(_ data: [Double]) -> TimeFeatures {
        return TimeFeatures(
            meanAmplitude: data.reduce(0, +) / Double(data.count),
            peakToPeak: data.max()! - data.min()!,
            rmsValue: sqrt(data.map { $0 * $0 }.reduce(0, +) / Double(data.count)),
            zeroCrossings: countZeroCrossings(data)
        )
    }
    
    private func extractStatisticalFeatures(_ data: [Double]) -> StatisticalFeatures {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        
        return StatisticalFeatures(
            mean: mean,
            variance: variance,
            skewness: calculateSkewness(data, mean: mean),
            kurtosis: calculateKurtosis(data, mean: mean)
        )
    }
    
    private func extractVariabilityFeatures(_ data: [Double]) -> VariabilityFeatures {
        // Calculate successive differences
        var differences: [Double] = []
        for i in 1..<data.count {
            differences.append(abs(data[i] - data[i-1]))
        }
        
        let meanDiff = differences.reduce(0, +) / Double(differences.count)
        
        return VariabilityFeatures(
            rmssd: sqrt(differences.map { $0 * $0 }.reduce(0, +) / Double(differences.count)),
            pnn50: calculatePNN50(differences),
            triangularIndex: calculateTriangularIndex(data),
            sdnn: sqrt(data.map { pow($0 - data.reduce(0, +) / Double(data.count), 2) }.reduce(0, +) / Double(data.count))
        )
    }
    
    // MARK: - Feature Comparison Methods
    
    private func compareFrequencyFeatures(_ f1: FrequencyFeatures, _ f2: FrequencyFeatures) -> Double {
        let similarities = [
            1.0 - abs(f1.dominantFrequency - f2.dominantFrequency) / max(f1.dominantFrequency, f2.dominantFrequency),
            1.0 - abs(f1.spectralCentroid - f2.spectralCentroid) / max(f1.spectralCentroid, f2.spectralCentroid),
            1.0 - abs(f1.spectralSpread - f2.spectralSpread) / max(f1.spectralSpread, f2.spectralSpread),
            1.0 - abs(f1.spectralRolloff - f2.spectralRolloff) / max(f1.spectralRolloff, f2.spectralRolloff)
        ]
        
        return similarities.reduce(0, +) / Double(similarities.count)
    }
    
    private func compareTimeFeatures(_ t1: TimeFeatures, _ t2: TimeFeatures) -> Double {
        let similarities = [
            1.0 - abs(t1.meanAmplitude - t2.meanAmplitude) / max(t1.meanAmplitude, t2.meanAmplitude),
            1.0 - abs(t1.peakToPeak - t2.peakToPeak) / max(t1.peakToPeak, t2.peakToPeak),
            1.0 - abs(t1.rmsValue - t2.rmsValue) / max(t1.rmsValue, t2.rmsValue),
            1.0 - abs(Double(t1.zeroCrossings - t2.zeroCrossings)) / Double(max(t1.zeroCrossings, t2.zeroCrossings))
        ]
        
        return similarities.reduce(0, +) / Double(similarities.count)
    }
    
    private func compareStatisticalFeatures(_ s1: StatisticalFeatures, _ s2: StatisticalFeatures) -> Double {
        let similarities = [
            1.0 - abs(s1.mean - s2.mean) / max(s1.mean, s2.mean),
            1.0 - abs(s1.variance - s2.variance) / max(s1.variance, s2.variance),
            1.0 - abs(s1.skewness - s2.skewness) / max(abs(s1.skewness), abs(s2.skewness)),
            1.0 - abs(s1.kurtosis - s2.kurtosis) / max(abs(s1.kurtosis), abs(s2.kurtosis))
        ]
        
        return similarities.reduce(0, +) / Double(similarities.count)
    }
    
    private func compareVariabilityFeatures(_ v1: VariabilityFeatures, _ v2: VariabilityFeatures) -> Double {
        let similarities = [
            1.0 - abs(v1.rmssd - v2.rmssd) / max(v1.rmssd, v2.rmssd),
            1.0 - abs(v1.pnn50 - v2.pnn50) / max(v1.pnn50, v2.pnn50),
            1.0 - abs(v1.triangularIndex - v2.triangularIndex) / max(v1.triangularIndex, v2.triangularIndex),
            1.0 - abs(v1.sdnn - v2.sdnn) / max(v1.sdnn, v2.sdnn)
        ]
        
        return similarities.reduce(0, +) / Double(similarities.count)
    }
    
    // MARK: - Support Methods
    
    private func generatePatternId(from features: PatternFeatures) -> String {
        // Create a hash from the feature vector
        let featureString = "\(features.frequency.dominantFrequency)_\(features.time.meanAmplitude)_\(features.statistical.mean)_\(features.variability.rmssd)"
        return featureString.hash.description
    }
    
    private func calculatePatternConfidence(features: PatternFeatures, originalData: [Double]) -> Double {
        // Base confidence on data quality indicators
        let dataQuality = assessDataQuality(originalData)
        let featureConsistency = assessFeatureConsistency(features)
        
        return (dataQuality * 0.6) + (featureConsistency * 0.4)
    }
    
    private func assessDataQuality(_ data: [Double]) -> Double {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let stdDev = sqrt(variance)
        
        // Quality indicators
        let lengthScore = min(Double(data.count) / Double(Constants.maxSampleCount), 1.0)
        let variabilityScore = min(stdDev / 20.0, 1.0) // Normalize by expected HR variability
        let rangeScore = (mean >= 50 && mean <= 150) ? 1.0 : 0.5 // Realistic HR range
        
        return (lengthScore * 0.4) + (variabilityScore * 0.4) + (rangeScore * 0.2)
    }
    
    private func assessFeatureConsistency(_ features: PatternFeatures) -> Double {
        // Check if features are within expected ranges
        let frequencyConsistency = (features.frequency.dominantFrequency > 0) ? 1.0 : 0.0
        let timeConsistency = (features.time.meanAmplitude > 0) ? 1.0 : 0.0
        let statisticalConsistency = (features.statistical.variance > 0) ? 1.0 : 0.0
        let variabilityConsistency = (features.variability.rmssd > 0) ? 1.0 : 0.0
        
        return (frequencyConsistency + timeConsistency + statisticalConsistency + variabilityConsistency) / 4.0
    }
    
    private func calculateTemporalStability(_ pattern1: XenonXResult, _ pattern2: XenonXResult) -> Double {
        // Factor in time between captures - too close or too far apart reduces confidence
        let timeDiff = abs(pattern1.timestamp.timeIntervalSince(pattern2.timestamp))
        
        if timeDiff < 60 { // Less than 1 minute
            return 0.8 // Might be too close for natural variation
        } else if timeDiff > 3600 * 24 * 7 { // More than 1 week
            return 0.9 // Pattern might have changed naturally
        } else {
            return 1.0 // Good temporal separation
        }
    }
    
    private func packageAnalysisData(features: PatternFeatures, preprocessed: [Double]) -> Data {
        let packagedData = AnalysisPackage(
            features: features,
            preprocessedData: preprocessed,
            timestamp: Date(),
            version: "XenonX-1.0"
        )
        
        do {
            return try JSONEncoder().encode(packagedData)
        } catch {
            debugLog.error("❌ Failed to package analysis data: \(error)")
            return Data()
        }
    }
    
    private func extractFeaturesFromAnalysisData(_ data: Data) -> PatternFeatures? {
        do {
            let package = try JSONDecoder().decode(AnalysisPackage.self, from: data)
            return package.features
        } catch {
            debugLog.error("❌ Failed to extract features from analysis data: \(error)")
            return nil
        }
    }
    
    private func createEmptyResult(reason: String) -> XenonXResult {
        let emptyFeatures = PatternFeatures(
            frequency: FrequencyFeatures(dominantFrequency: 0, spectralCentroid: 0, spectralSpread: 0, spectralRolloff: 0),
            time: TimeFeatures(meanAmplitude: 0, peakToPeak: 0, rmsValue: 0, zeroCrossings: 0),
            statistical: StatisticalFeatures(mean: 0, variance: 0, skewness: 0, kurtosis: 0),
            variability: VariabilityFeatures(rmssd: 0, pnn50: 0, triangularIndex: 0, sdnn: 0)
        )
        
        let analysisData = try! JSONEncoder().encode(AnalysisPackage(
            features: emptyFeatures,
            preprocessedData: [],
            timestamp: Date(),
            version: "XenonX-1.0"
        ))
        
        return XenonXResult(patternId: "empty", confidence: 0.0, analysisData: analysisData)
    }
    
    // MARK: - Mathematical Helper Methods
    
    private func performFFT(_ data: [Double]) -> [Double] {
        // Simplified FFT - in production this would use Accelerate framework
        // For now, return mock frequency domain data
        var result: [Double] = []
        for i in 0..<min(Constants.fftSize, data.count) {
            result.append(sin(Double(i) * 0.1) * data[i])
        }
        return result
    }
    
    private func findDominantFrequency(_ fftData: [Double]) -> Double {
        guard let maxIndex = fftData.enumerated().max(by: { $0.element < $1.element })?.offset else { return 0 }
        return Double(maxIndex) / Double(fftData.count) * 100.0 // Normalized frequency
    }
    
    private func calculateSpectralCentroid(_ fftData: [Double]) -> Double {
        let weightedSum = fftData.enumerated().reduce(0.0) { $0 + ($1.element * Double($1.offset)) }
        let totalMagnitude = fftData.reduce(0, +)
        return totalMagnitude > 0 ? weightedSum / totalMagnitude : 0
    }
    
    private func calculateSpectralSpread(_ fftData: [Double]) -> Double {
        let centroid = calculateSpectralCentroid(fftData)
        let totalMagnitude = fftData.reduce(0, +)
        if totalMagnitude == 0 { return 0 }
        
        let weightedVariance = fftData.enumerated().reduce(0.0) { 
            $0 + ($1.element * pow(Double($1.offset) - centroid, 2))
        }
        return sqrt(weightedVariance / totalMagnitude)
    }
    
    private func calculateSpectralRolloff(_ fftData: [Double]) -> Double {
        let totalEnergy = fftData.map { $0 * $0 }.reduce(0, +)
        let threshold = totalEnergy * 0.85 // 85% of total energy
        
        var cumulativeEnergy = 0.0
        for (index, magnitude) in fftData.enumerated() {
            cumulativeEnergy += magnitude * magnitude
            if cumulativeEnergy >= threshold {
                return Double(index)
            }
        }
        return Double(fftData.count - 1)
    }
    
    private func countZeroCrossings(_ data: [Double]) -> Int {
        var count = 0
        let mean = data.reduce(0, +) / Double(data.count)
        let centeredData = data.map { $0 - mean }
        
        for i in 1..<centeredData.count {
            if (centeredData[i] * centeredData[i-1]) < 0 {
                count += 1
            }
        }
        return count
    }
    
    private func calculateSkewness(_ data: [Double], mean: Double) -> Double {
        let n = Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / n
        let stdDev = sqrt(variance)
        
        if stdDev == 0 { return 0 }
        
        let skewness = data.map { pow(($0 - mean) / stdDev, 3) }.reduce(0, +) / n
        return skewness
    }
    
    private func calculateKurtosis(_ data: [Double], mean: Double) -> Double {
        let n = Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / n
        let stdDev = sqrt(variance)
        
        if stdDev == 0 { return 0 }
        
        let kurtosis = data.map { pow(($0 - mean) / stdDev, 4) }.reduce(0, +) / n - 3.0
        return kurtosis
    }
    
    private func calculatePNN50(_ differences: [Double]) -> Double {
        let count = differences.filter { $0 > 50.0 }.count
        return Double(count) / Double(differences.count) * 100.0
    }
    
    private func calculateTriangularIndex(_ data: [Double]) -> Double {
        // Simplified triangular index calculation
        let sortedData = data.sorted()
        let median = sortedData[sortedData.count / 2]
        let range = sortedData.last! - sortedData.first!
        return range / median
    }
}

// MARK: - Supporting Data Structures

struct PatternFeatures: Codable {
    let frequency: FrequencyFeatures
    let time: TimeFeatures
    let statistical: StatisticalFeatures
    let variability: VariabilityFeatures
}

struct FrequencyFeatures: Codable {
    let dominantFrequency: Double
    let spectralCentroid: Double
    let spectralSpread: Double
    let spectralRolloff: Double
}

struct TimeFeatures: Codable {
    let meanAmplitude: Double
    let peakToPeak: Double
    let rmsValue: Double
    let zeroCrossings: Int
}

struct StatisticalFeatures: Codable {
    let mean: Double
    let variance: Double
    let skewness: Double
    let kurtosis: Double
}

struct VariabilityFeatures: Codable {
    let rmssd: Double
    let pnn50: Double
    let triangularIndex: Double
    let sdnn: Double
}

struct AnalysisPackage: Codable {
    let features: PatternFeatures
    let preprocessedData: [Double]
    let timestamp: Date
    let version: String
}