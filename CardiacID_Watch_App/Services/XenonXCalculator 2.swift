//
//  XenonXCalculator.swift
//  HeartID Watch App
//
//  Advanced biometric pattern analysis for enterprise security
//

import Foundation
import Accelerate
import CryptoKit

/// Enterprise-grade biometric pattern analysis calculator
class XenonXCalculator {
    
    // MARK: - Configuration Constants
    
    private let minimumSampleSize = 200
    private let analysisWindowSize = 60
    private let confidenceThreshold = 0.75
    private let maxPatternDeviation = 0.25
    
    // MARK: - Pattern Analysis
    
    /// Analyze heart rate pattern using advanced signal processing
    func analyzePattern(_ heartRateData: [Double]) -> XenonXResult {
        print("🔬 XenonX: Analyzing pattern with \(heartRateData.count) samples")
        
        guard heartRateData.count >= minimumSampleSize else {
            return XenonXResult(
                patternId: "insufficient_data",
                confidence: 0.0,
                analysisData: Data()
            )
        }
        
        // 1. Signal preprocessing
        let preprocessedData = preprocessSignal(heartRateData)
        
        // 2. Extract biometric features
        let features = extractBiometricFeatures(preprocessedData)
        
        // 3. Generate pattern signature
        let patternSignature = generatePatternSignature(features)
        
        // 4. Calculate confidence score
        let confidence = calculatePatternConfidence(features)
        
        // 5. Encode analysis data
        let analysisData = encodeAnalysisData(features)
        
        print("✅ XenonX: Pattern analysis complete - Confidence: \(String(format: "%.3f", confidence))")
        
        return XenonXResult(
            patternId: patternSignature,
            confidence: confidence,
            analysisData: analysisData
        )
    }
    
    /// Compare two biometric patterns for authentication
    func comparePatterns(_ storedPattern: XenonXResult, _ currentPattern: XenonXResult) -> Double {
        print("🔄 XenonX: Comparing patterns")
        
        guard storedPattern.analysisData.count > 0 && currentPattern.analysisData.count > 0 else {
            print("❌ XenonX: Invalid pattern data for comparison")
            return 0.0
        }
        
        // Decode stored features
        guard let storedFeatures = decodeAnalysisData(storedPattern.analysisData),
              let currentFeatures = decodeAnalysisData(currentPattern.analysisData) else {
            print("❌ XenonX: Failed to decode pattern features")
            return 0.0
        }
        
        // 1. Calculate feature similarity scores
        let temporalSimilarity = compareTemporalFeatures(storedFeatures, currentFeatures)
        let frequencyMatch = compareFrequencyFeatures(storedFeatures, currentFeatures)
        let statisticalMatch = compareStatisticalFeatures(storedFeatures, currentFeatures)
        let morphologyMatch = compareMorphologyFeatures(storedFeatures, currentFeatures)
        
        // 2. Weighted fusion of similarity scores
        let weightedSimilarity = (
            temporalSimilarity * 0.3 +
            frequencyMatch * 0.25 +
            statisticalMatch * 0.25 +
            morphologyMatch * 0.2
        )
        
        // 3. Apply confidence weighting
        let confidenceWeight = min(storedPattern.confidence, currentPattern.confidence)
        let finalSimilarity = weightedSimilarity * confidenceWeight
        
        print("📊 XenonX: Pattern similarity - \(String(format: "%.3f", finalSimilarity))")
        print("   - Temporal: \(String(format: "%.3f", temporalSimilarity))")
        print("   - Frequency: \(String(format: "%.3f", frequencyMatch))")
        print("   - Statistical: \(String(format: "%.3f", statisticalMatch))")
        print("   - Morphology: \(String(format: "%.3f", morphologyMatch))")
        
        return finalSimilarity
    }
    
    // MARK: - Signal Processing
    
    private func preprocessSignal(_ data: [Double]) -> [Double] {
        // 1. Remove outliers using IQR method
        let cleanedData = removeOutliers(data)
        
        // 2. Apply median filter for noise reduction
        let filteredData = applyMedianFilter(cleanedData)
        
        // 3. Normalize signal
        let normalizedData = normalizeSignal(filteredData)
        
        return normalizedData
    }
    
    private func removeOutliers(_ data: [Double]) -> [Double] {
        let sortedData = data.sorted()
        let count = sortedData.count
        
        guard count > 4 else { return data }
        
        let q1 = sortedData[count / 4]
        let q3 = sortedData[3 * count / 4]
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        return data.filter { $0 >= lowerBound && $0 <= upperBound }
    }
    
    private func applyMedianFilter(_ data: [Double]) -> [Double] {
        let windowSize = 5
        var filtered: [Double] = []
        
        for i in 0..<data.count {
            let start = max(0, i - windowSize / 2)
            let end = min(data.count, i + windowSize / 2 + 1)
            let window = Array(data[start..<end]).sorted()
            
            filtered.append(window[window.count / 2])
        }
        
        return filtered
    }
    
    private func normalizeSignal(_ data: [Double]) -> [Double] {
        guard !data.isEmpty else { return data }
        
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let stdDev = sqrt(variance)
        
        guard stdDev > 0 else { return data }
        
        return data.map { ($0 - mean) / stdDev }
    }
    
    // MARK: - Feature Extraction
    
    private func extractBiometricFeatures(_ data: [Double]) -> BiometricFeatures {
        // Temporal features
        let meanRR = calculateMeanRR(data)
        let rmssd = calculateRMSSD(data)
        let sdnn = calculateSDNN(data)
        let pnn50 = calculatePNN50(data)
        
        // Frequency domain features
        let frequencyFeatures = extractFrequencyFeatures(data)
        
        // Morphology features
        let morphologyFeatures = extractMorphologyFeatures(data)
        
        // Statistical features
        let statisticalFeatures = extractStatisticalFeatures(data)
        
        return BiometricFeatures(
            meanRR: meanRR,
            rmssd: rmssd,
            sdnn: sdnn,
            pnn50: pnn50,
            lowFrequency: frequencyFeatures.lf,
            highFrequency: frequencyFeatures.hf,
            lfhfRatio: frequencyFeatures.lfhfRatio,
            peakAmplitude: morphologyFeatures.peakAmplitude,
            peakWidth: morphologyFeatures.peakWidth,
            slopeVariation: morphologyFeatures.slopeVariation,
            skewness: statisticalFeatures.skewness,
            kurtosis: statisticalFeatures.kurtosis,
            entropy: statisticalFeatures.entropy
        )
    }
    
    private func calculateRMSSD(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0 }
        
        let differences = zip(data, data.dropFirst()).map { abs($1 - $0) }
        let squaredDifferences = differences.map { $0 * $0 }
        let meanSquared = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
        
        return sqrt(meanSquared)
    }
    
    private func calculateSDNN(_ data: [Double]) -> Double {
        guard !data.isEmpty else { return 0 }
        
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        
        return sqrt(variance)
    }
    
    private func calculatePNN50(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0 }
        
        let differences = zip(data, data.dropFirst()).map { abs($1 - $0) }
        let over50 = differences.filter { $0 > 50 }.count
        
        return Double(over50) / Double(differences.count)
    }
    
    private func calculateMeanRR(_ data: [Double]) -> Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0, +) / Double(data.count)
    }
    
    // MARK: - Advanced Feature Extraction
    
    private func extractFrequencyFeatures(_ data: [Double]) -> FrequencyFeatures {
        // Simplified frequency analysis - in production this would use FFT
        let variance = calculateSDNN(data)
        let lfPower = variance * 0.6  // Low frequency approximation
        let hfPower = variance * 0.4  // High frequency approximation
        let lfhfRatio = lfPower / max(hfPower, 0.001)
        
        return FrequencyFeatures(lf: lfPower, hf: hfPower, lfhfRatio: lfhfRatio)
    }
    
    private func extractMorphologyFeatures(_ data: [Double]) -> MorphologyFeatures {
        guard !data.isEmpty else {
            return MorphologyFeatures(peakAmplitude: 0, peakWidth: 0, slopeVariation: 0)
        }
        
        let maxValue = data.max() ?? 0
        let minValue = data.min() ?? 0
        let peakAmplitude = maxValue - minValue
        
        // Simplified morphology analysis
        let peakWidth = Double(data.count) / 10.0  // Approximation
        let slopes = zip(data, data.dropFirst()).map { $1 - $0 }
        let slopeVariation = calculateSDNN(slopes)
        
        return MorphologyFeatures(
            peakAmplitude: peakAmplitude,
            peakWidth: peakWidth,
            slopeVariation: slopeVariation
        )
    }
    
    private func extractStatisticalFeatures(_ data: [Double]) -> StatisticalFeatures {
        guard !data.isEmpty else {
            return StatisticalFeatures(skewness: 0, kurtosis: 0, entropy: 0)
        }
        
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let stdDev = sqrt(variance)
        
        // Skewness calculation
        let skewness = data.map { pow(($0 - mean) / stdDev, 3) }.reduce(0, +) / Double(data.count)
        
        // Kurtosis calculation
        let kurtosis = data.map { pow(($0 - mean) / stdDev, 4) }.reduce(0, +) / Double(data.count) - 3
        
        // Simplified entropy calculation
        let entropy = log2(Double(data.count)) * 0.8  // Approximation
        
        return StatisticalFeatures(skewness: skewness, kurtosis: kurtosis, entropy: entropy)
    }
    
    // MARK: - Pattern Comparison
    
    private func compareTemporalFeatures(_ stored: BiometricFeatures, _ current: BiometricFeatures) -> Double {
        let rmssdSim = 1.0 - min(1.0, abs(stored.rmssd - current.rmssd) / max(stored.rmssd, current.rmssd, 1.0))
        let sdnnSim = 1.0 - min(1.0, abs(stored.sdnn - current.sdnn) / max(stored.sdnn, current.sdnn, 1.0))
        let pnn50Sim = 1.0 - min(1.0, abs(stored.pnn50 - current.pnn50))
        
        return (rmssdSim + sdnnSim + pnn50Sim) / 3.0
    }
    
    private func compareFrequencyFeatures(_ stored: BiometricFeatures, _ current: BiometricFeatures) -> Double {
        let lfSim = 1.0 - min(1.0, abs(stored.lowFrequency - current.lowFrequency) / max(stored.lowFrequency, current.lowFrequency, 1.0))
        let hfSim = 1.0 - min(1.0, abs(stored.highFrequency - current.highFrequency) / max(stored.highFrequency, current.highFrequency, 1.0))
        let ratioSim = 1.0 - min(1.0, abs(stored.lfhfRatio - current.lfhfRatio) / max(stored.lfhfRatio, current.lfhfRatio, 1.0))
        
        return (lfSim + hfSim + ratioSim) / 3.0
    }
    
    private func compareStatisticalFeatures(_ stored: BiometricFeatures, _ current: BiometricFeatures) -> Double {
        let skewSim = 1.0 - min(1.0, abs(stored.skewness - current.skewness) / 4.0)  // Normalized by typical skewness range
        let kurtSim = 1.0 - min(1.0, abs(stored.kurtosis - current.kurtosis) / 6.0)   // Normalized by typical kurtosis range
        let entropySim = 1.0 - min(1.0, abs(stored.entropy - current.entropy) / max(stored.entropy, current.entropy, 1.0))
        
        return (skewSim + kurtSim + entropySim) / 3.0
    }
    
    private func compareMorphologyFeatures(_ stored: BiometricFeatures, _ current: BiometricFeatures) -> Double {
        let ampSim = 1.0 - min(1.0, abs(stored.peakAmplitude - current.peakAmplitude) / max(stored.peakAmplitude, current.peakAmplitude, 1.0))
        let widthSim = 1.0 - min(1.0, abs(stored.peakWidth - current.peakWidth) / max(stored.peakWidth, current.peakWidth, 1.0))
        let slopeSim = 1.0 - min(1.0, abs(stored.slopeVariation - current.slopeVariation) / max(stored.slopeVariation, current.slopeVariation, 1.0))
        
        return (ampSim + widthSim + slopeSim) / 3.0
    }
    
    // MARK: - Pattern Signature Generation
    
    private func generatePatternSignature(_ features: BiometricFeatures) -> String {
        // Create a unique signature based on biometric features
        let signatureData = "\(features.meanRR)_\(features.rmssd)_\(features.sdnn)_\(features.pnn50)_\(features.lfhfRatio)"
        
        // Hash the signature for privacy
        let inputData = Data(signatureData.utf8)
        let digest = SHA256.hash(data: inputData)
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func calculatePatternConfidence(_ features: BiometricFeatures) -> Double {
        // Assess pattern quality based on feature characteristics
        var confidence = 0.5  // Base confidence
        
        // RMSSD quality check
        if features.rmssd >= 20 && features.rmssd <= 100 {
            confidence += 0.15
        }
        
        // SDNN quality check
        if features.sdnn >= 30 && features.sdnn <= 150 {
            confidence += 0.15
        }
        
        // pNN50 quality check
        if features.pnn50 >= 0.05 && features.pnn50 <= 0.5 {
            confidence += 0.1
        }
        
        // LF/HF ratio quality check
        if features.lfhfRatio >= 0.5 && features.lfhfRatio <= 4.0 {
            confidence += 0.1
        }
        
        return min(0.98, confidence)  // Cap at 98% confidence
    }
    
    // MARK: - Data Encoding/Decoding
    
    private func encodeAnalysisData(_ features: BiometricFeatures) -> Data {
        do {
            return try JSONEncoder().encode(features)
        } catch {
            print("❌ XenonX: Failed to encode analysis data: \(error)")
            return Data()
        }
    }
    
    private func decodeAnalysisData(_ data: Data) -> BiometricFeatures? {
        do {
            return try JSONDecoder().decode(BiometricFeatures.self, from: data)
        } catch {
            print("❌ XenonX: Failed to decode analysis data: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Data Structures

struct BiometricFeatures: Codable {
    let meanRR: Double
    let rmssd: Double
    let sdnn: Double
    let pnn50: Double
    let lowFrequency: Double
    let highFrequency: Double
    let lfhfRatio: Double
    let peakAmplitude: Double
    let peakWidth: Double
    let slopeVariation: Double
    let skewness: Double
    let kurtosis: Double
    let entropy: Double
}

private struct FrequencyFeatures {
    let lf: Double
    let hf: Double
    let lfhfRatio: Double
}

private struct MorphologyFeatures {
    let peakAmplitude: Double
    let peakWidth: Double
    let slopeVariation: Double
}

private struct StatisticalFeatures {
    let skewness: Double
    let kurtosis: Double
    let entropy: Double
}