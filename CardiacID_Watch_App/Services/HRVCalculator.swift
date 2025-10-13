//
//  HRVCalculator.swift
//  HeartID Watch App
//
//  Advanced Heart Rate Variability analysis for biometric authentication
//

import Foundation
import Accelerate

/// Advanced HRV calculator for biometric pattern analysis
struct HRVCalculator {
    
    // MARK: - HRV Features Structure
    
    struct HRVFeatures: Codable {
        let rmssd: Double              // Root Mean Square of Successive Differences
        let pnn50: Double              // Percentage of NN50 intervals
        let sdnn: Double               // Standard Deviation of NN intervals
        let meanRR: Double             // Mean RR interval
        let heartRateVariability: Double // Overall HRV measure
        let sdsd: Double               // Standard Deviation of Successive Differences
        let nn50: Int                  // Number of NN50 intervals
        let triangularIndex: Double    // Triangular Index
        let stressIndex: Double        // Stress Index
        
        init(rmssd: Double, pnn50: Double, sdnn: Double, meanRR: Double, 
             heartRateVariability: Double, sdsd: Double, nn50: Int, 
             triangularIndex: Double, stressIndex: Double) {
            self.rmssd = rmssd
            self.pnn50 = pnn50
            self.sdnn = sdnn
            self.meanRR = meanRR
            self.heartRateVariability = heartRateVariability
            self.sdsd = sdsd
            self.nn50 = nn50
            self.triangularIndex = triangularIndex
            self.stressIndex = stressIndex
        }
        
        /// Quality assessment of HRV features
        var qualityScore: Double {
            var score = 0.0
            
            // RMSSD quality (healthy range: 20-100ms)
            if rmssd >= 20 && rmssd <= 100 {
                score += 0.25
            } else if rmssd >= 10 && rmssd <= 150 {
                score += 0.15
            }
            
            // pNN50 quality (healthy range: 0.05-0.5)
            if pnn50 >= 0.05 && pnn50 <= 0.5 {
                score += 0.25
            } else if pnn50 >= 0.01 && pnn50 <= 0.8 {
                score += 0.15
            }
            
            // SDNN quality (healthy range: 30-150ms)
            if sdnn >= 30 && sdnn <= 150 {
                score += 0.25
            } else if sdnn >= 15 && sdnn <= 200 {
                score += 0.15
            }
            
            // Overall variability check
            if heartRateVariability > 5 && heartRateVariability < 50 {
                score += 0.25
            } else if heartRateVariability > 2 && heartRateVariability < 80 {
                score += 0.15
            }
            
            return min(1.0, score)
        }
        
        /// Health assessment based on HRV metrics
        var healthAssessment: HealthAssessment {
            // Simplified health assessment based on key HRV metrics
            if rmssd >= 40 && pnn50 >= 0.15 && sdnn >= 50 {
                return .excellent
            } else if rmssd >= 25 && pnn50 >= 0.08 && sdnn >= 35 {
                return .good
            } else if rmssd >= 15 && pnn50 >= 0.03 && sdnn >= 20 {
                return .fair
            } else {
                return .poor
            }
        }
    }
    
    enum HealthAssessment: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var description: String {
            switch self {
            case .excellent:
                return "High parasympathetic activity, good recovery capacity"
            case .good:
                return "Balanced autonomic function"
            case .fair:
                return "Moderate autonomic function"
            case .poor:
                return "Low variability, potential stress or fatigue"
            }
        }
    }
    
    // MARK: - Main HRV Calculation
    
    /// Calculate comprehensive HRV features from heart rate data
    static func calculateHRV(_ heartRateData: [Double]) -> HRVFeatures {
        print("📊 Calculating HRV from \(heartRateData.count) heart rate samples")
        
        guard heartRateData.count >= 50 else {
            print("⚠️ Insufficient data for HRV analysis")
            return HRVFeatures(rmssd: 0, pnn50: 0, sdnn: 0, meanRR: 0, 
                              heartRateVariability: 0, sdsd: 0, nn50: 0, 
                              triangularIndex: 0, stressIndex: 0)
        }
        
        // Convert heart rate to RR intervals (in milliseconds)
        let rrIntervals = convertHeartRateToRRIntervals(heartRateData)
        
        // Filter out invalid RR intervals
        let validRRIntervals = filterValidRRIntervals(rrIntervals)
        
        guard validRRIntervals.count >= 30 else {
            print("⚠️ Too few valid RR intervals for reliable HRV analysis")
            return HRVFeatures(rmssd: 0, pnn50: 0, sdnn: 0, meanRR: 0, 
                              heartRateVariability: 0, sdsd: 0, nn50: 0, 
                              triangularIndex: 0, stressIndex: 0)
        }
        
        // Calculate all HRV metrics
        let rmssd = calculateRMSSD(validRRIntervals)
        let pnn50Data = calculatePNN50(validRRIntervals)
        let sdnn = calculateSDNN(validRRIntervals)
        let meanRR = calculateMeanRR(validRRIntervals)
        let sdsd = calculateSDSD(validRRIntervals)
        let triangularIndex = calculateTriangularIndex(validRRIntervals)
        let stressIndex = calculateStressIndex(validRRIntervals, meanRR: meanRR)
        
        // Calculate overall HRV measure
        let hrv = calculateOverallHRV(rmssd: rmssd, sdnn: sdnn, pnn50: pnn50Data.pnn50)
        
        let features = HRVFeatures(
            rmssd: rmssd,
            pnn50: pnn50Data.pnn50,
            sdnn: sdnn,
            meanRR: meanRR,
            heartRateVariability: hrv,
            sdsd: sdsd,
            nn50: pnn50Data.nn50,
            triangularIndex: triangularIndex,
            stressIndex: stressIndex
        )
        
        print("✅ HRV Analysis Complete:")
        print("   - RMSSD: \(String(format: "%.2f", rmssd))ms")
        print("   - pNN50: \(String(format: "%.3f", pnn50Data.pnn50))")
        print("   - SDNN: \(String(format: "%.2f", sdnn))ms")
        print("   - Mean RR: \(String(format: "%.2f", meanRR))ms")
        print("   - Quality Score: \(String(format: "%.2f", features.qualityScore))")
        print("   - Health Assessment: \(features.healthAssessment.rawValue)")
        
        return features
    }
    
    // MARK: - RR Interval Conversion
    
    private static func convertHeartRateToRRIntervals(_ heartRates: [Double]) -> [Double] {
        return heartRates.map { heartRate in
            guard heartRate > 0 else { return 0 }
            return 60000.0 / heartRate  // Convert BPM to RR interval in milliseconds
        }
    }
    
    private static func filterValidRRIntervals(_ intervals: [Double]) -> [Double] {
        // Filter out physiologically implausible RR intervals
        // Normal RR intervals: 300ms (200 BPM) to 2000ms (30 BPM)
        return intervals.filter { interval in
            interval >= 300 && interval <= 2000
        }
    }
    
    // MARK: - Time Domain HRV Metrics
    
    /// Calculate Root Mean Square of Successive Differences (RMSSD)
    private static func calculateRMSSD(_ intervals: [Double]) -> Double {
        guard intervals.count > 1 else { return 0 }
        
        let successiveDifferences = zip(intervals, intervals.dropFirst()).map { abs($1 - $0) }
        let squaredDifferences = successiveDifferences.map { $0 * $0 }
        let meanSquared = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
        
        return sqrt(meanSquared)
    }
    
    /// Calculate Standard Deviation of NN intervals (SDNN)
    private static func calculateSDNN(_ intervals: [Double]) -> Double {
        guard intervals.count > 1 else { return 0 }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let squaredDeviations = intervals.map { pow($0 - mean, 2) }
        let variance = squaredDeviations.reduce(0, +) / Double(intervals.count - 1)
        
        return sqrt(variance)
    }
    
    /// Calculate Standard Deviation of Successive Differences (SDSD)
    private static func calculateSDSD(_ intervals: [Double]) -> Double {
        guard intervals.count > 1 else { return 0 }
        
        let successiveDifferences = zip(intervals, intervals.dropFirst()).map { $1 - $0 }
        let meanDifference = successiveDifferences.reduce(0, +) / Double(successiveDifferences.count)
        let squaredDeviations = successiveDifferences.map { pow($0 - meanDifference, 2) }
        let variance = squaredDeviations.reduce(0, +) / Double(successiveDifferences.count - 1)
        
        return sqrt(variance)
    }
    
    /// Calculate percentage of NN50 intervals (pNN50)
    private static func calculatePNN50(_ intervals: [Double]) -> (pnn50: Double, nn50: Int) {
        guard intervals.count > 1 else { return (0, 0) }
        
        let successiveDifferences = zip(intervals, intervals.dropFirst()).map { abs($1 - $0) }
        let nn50Count = successiveDifferences.filter { $0 > 50 }.count
        let pnn50 = Double(nn50Count) / Double(successiveDifferences.count)
        
        return (pnn50, nn50Count)
    }
    
    /// Calculate mean RR interval
    private static func calculateMeanRR(_ intervals: [Double]) -> Double {
        guard !intervals.isEmpty else { return 0 }
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    // MARK: - Geometric HRV Metrics
    
    /// Calculate Triangular Index
    private static func calculateTriangularIndex(_ intervals: [Double]) -> Double {
        guard intervals.count > 50 else { return 0 }
        
        // Create histogram with 7.8125ms bins (1/128 second)
        let binWidth = 7.8125
        let minInterval = intervals.min() ?? 0
        let maxInterval = intervals.max() ?? 0
        let numberOfBins = Int((maxInterval - minInterval) / binWidth) + 1
        
        var histogram = Array(repeating: 0, count: numberOfBins)
        
        for interval in intervals {
            let binIndex = Int((interval - minInterval) / binWidth)
            if binIndex >= 0 && binIndex < numberOfBins {
                histogram[binIndex] += 1
            }
        }
        
        let maxFrequency = histogram.max() ?? 1
        return Double(intervals.count) / Double(maxFrequency)
    }
    
    /// Calculate Stress Index (Baevsky's method)
    private static func calculateStressIndex(_ intervals: [Double], meanRR: Double) -> Double {
        guard intervals.count > 10 else { return 0 }
        
        // Mode calculation (most frequent RR interval)
        let binWidth = 50.0  // 50ms bins
        let minInterval = intervals.min() ?? 0
        let maxInterval = intervals.max() ?? 0
        let numberOfBins = Int((maxInterval - minInterval) / binWidth) + 1
        
        var histogram = Array(repeating: 0, count: numberOfBins)
        var binCenters: [Double] = []
        
        for i in 0..<numberOfBins {
            binCenters.append(minInterval + Double(i) * binWidth + binWidth / 2)
            histogram[i] = 0
        }
        
        for interval in intervals {
            let binIndex = Int((interval - minInterval) / binWidth)
            if binIndex >= 0 && binIndex < numberOfBins {
                histogram[binIndex] += 1
            }
        }
        
        // Find mode (most frequent value)
        let maxFrequencyIndex = histogram.firstIndex(of: histogram.max() ?? 0) ?? 0
        let mode = binCenters[maxFrequencyIndex]
        let modeFrequency = histogram[maxFrequencyIndex]
        
        // Calculate amplitude of mode (AMo) as percentage
        let amo = Double(modeFrequency) / Double(intervals.count) * 100
        
        // Calculate variation range
        let variationRange = maxInterval - minInterval
        
        // Stress Index = AMo / (2 * Mo * ΔX) where Mo is mode and ΔX is variation range
        let stressIndex = amo / (2.0 * mode * variationRange / 1000000.0)  // Convert to appropriate units
        
        return stressIndex
    }
    
    // MARK: - Overall HRV Calculation
    
    private static func calculateOverallHRV(rmssd: Double, sdnn: Double, pnn50: Double) -> Double {
        // Weighted combination of key HRV metrics
        let normalizedRMSSD = min(rmssd / 100.0, 1.0)  // Normalize to 0-1 range
        let normalizedSDNN = min(sdnn / 150.0, 1.0)    // Normalize to 0-1 range
        let normalizedPNN50 = min(pnn50 / 0.5, 1.0)    // Normalize to 0-1 range
        
        // Weighted average (RMSSD has higher weight for short-term recordings)
        return (normalizedRMSSD * 0.5 + normalizedSDNN * 0.3 + normalizedPNN50 * 0.2) * 100.0
    }
    
    // MARK: - Frequency Domain Analysis (Simplified)
    
    /// Calculate frequency domain HRV metrics (simplified implementation)
    static func calculateFrequencyDomainHRV(_ intervals: [Double]) -> FrequencyDomainFeatures {
        guard intervals.count >= 100 else {
            return FrequencyDomainFeatures(lf: 0, hf: 0, lfhfRatio: 0, totalPower: 0)
        }
        
        // Simplified frequency analysis - in production this would use FFT
        let sdnn = calculateSDNN(intervals)
        let rmssd = calculateRMSSD(intervals)
        
        // Approximate frequency domain measures based on time domain
        let totalPower = pow(sdnn, 2)
        let hfPower = pow(rmssd, 2) * 0.5  // High frequency approximation
        let lfPower = totalPower * 0.6 - hfPower  // Low frequency approximation
        let lfhfRatio = lfPower / max(hfPower, 0.001)
        
        return FrequencyDomainFeatures(
            lf: max(0, lfPower),
            hf: max(0, hfPower),
            lfhfRatio: lfhfRatio,
            totalPower: totalPower
        )
    }
    
    struct FrequencyDomainFeatures {
        let lf: Double          // Low Frequency Power
        let hf: Double          // High Frequency Power
        let lfhfRatio: Double   // LF/HF Ratio
        let totalPower: Double  // Total Power
    }
    
    // MARK: - HRV Analysis for Authentication
    
    /// Compare HRV features for biometric authentication
    static func compareHRVFeatures(_ stored: HRVFeatures, _ current: HRVFeatures) -> Double {
        // Weight different HRV components based on their stability for biometric use
        let rmssdSimilarity = calculateFeatureSimilarity(
            stored.rmssd, current.rmssd, maxDifference: 50.0
        )
        
        let pnn50Similarity = calculateFeatureSimilarity(
            stored.pnn50, current.pnn50, maxDifference: 0.3
        )
        
        let sdnnSimilarity = calculateFeatureSimilarity(
            stored.sdnn, current.sdnn, maxDifference: 75.0
        )
        
        let hrvSimilarity = calculateFeatureSimilarity(
            stored.heartRateVariability, current.heartRateVariability, maxDifference: 30.0
        )
        
        // Weighted combination (RMSSD and SDNN are most stable for identification)
        let overallSimilarity = (
            rmssdSimilarity * 0.4 +
            sdnnSimilarity * 0.3 +
            pnn50Similarity * 0.2 +
            hrvSimilarity * 0.1
        )
        
        return overallSimilarity
    }
    
    private static func calculateFeatureSimilarity(_ stored: Double, _ current: Double, maxDifference: Double) -> Double {
        let difference = abs(stored - current)
        let similarity = max(0.0, 1.0 - (difference / maxDifference))
        return similarity
    }
    
    // MARK: - HRV Quality Assessment
    
    /// Assess the quality of HRV data for biometric use
    static func assessHRVQuality(_ features: HRVFeatures) -> HRVQualityAssessment {
        var qualityScore = 0.0
        var issues: [String] = []
        var recommendations: [String] = []
        
        // RMSSD quality check
        if features.rmssd >= 20 && features.rmssd <= 100 {
            qualityScore += 0.25
        } else if features.rmssd < 10 {
            issues.append("Very low RMSSD")
            recommendations.append("Ensure calm state during measurement")
        } else if features.rmssd > 150 {
            issues.append("Unusually high RMSSD")
            recommendations.append("Reduce movement and artifacts")
        }
        
        // SDNN quality check
        if features.sdnn >= 30 && features.sdnn <= 150 {
            qualityScore += 0.25
        } else if features.sdnn < 15 {
            issues.append("Very low SDNN")
            recommendations.append("Extend measurement duration")
        }
        
        // pNN50 quality check
        if features.pnn50 >= 0.05 && features.pnn50 <= 0.5 {
            qualityScore += 0.25
        } else if features.pnn50 < 0.02 {
            issues.append("Low parasympathetic activity")
            recommendations.append("Ensure relaxed state")
        }
        
        // Overall HRV check
        if features.heartRateVariability > 10 {
            qualityScore += 0.25
        } else {
            issues.append("Low overall variability")
            recommendations.append("Check sensor contact and reduce stress")
        }
        
        let qualityLevel: HRVQualityLevel
        if qualityScore >= 0.8 {
            qualityLevel = .excellent
        } else if qualityScore >= 0.6 {
            qualityLevel = .good
        } else if qualityScore >= 0.4 {
            qualityLevel = .fair
        } else {
            qualityLevel = .poor
        }
        
        return HRVQualityAssessment(
            qualityScore: qualityScore,
            qualityLevel: qualityLevel,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    struct HRVQualityAssessment {
        let qualityScore: Double
        let qualityLevel: HRVQualityLevel
        let issues: [String]
        let recommendations: [String]
    }
    
    enum HRVQualityLevel: String {
        case excellent = "Excellent"
        case good = "Good" 
        case fair = "Fair"
        case poor = "Poor"
        
        var description: String {
            switch self {
            case .excellent:
                return "High quality HRV data suitable for biometric use"
            case .good:
                return "Good quality HRV data with minor variations"
            case .fair:
                return "Acceptable HRV data but may need optimization"
            case .poor:
                return "Poor quality HRV data, recapture recommended"
            }
        }
    }
}