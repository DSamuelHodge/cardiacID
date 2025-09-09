import Foundation

/// Model representing a heart pattern for biometric authentication
struct HeartPattern: Codable, Identifiable {
    let id: String
    let heartRateData: [Double]
    let qualityScore: Double
    let confidence: Double
    let timestamp: Date
    let deviceId: String?
    
    init(heartRateData: [Double], qualityScore: Double, confidence: Double, deviceId: String? = nil) {
        self.id = UUID().uuidString
        self.heartRateData = heartRateData
        self.qualityScore = qualityScore
        self.confidence = confidence
        self.timestamp = Date()
        self.deviceId = deviceId
    }
    
    // MARK: - Computed Properties
    
    var averageHeartRate: Double {
        guard !heartRateData.isEmpty else { return 0 }
        return heartRateData.reduce(0, +) / Double(heartRateData.count)
    }
    
    var isValid: Bool {
        return qualityScore > 0.7 && confidence > 0.8 && !heartRateData.isEmpty
    }
    
    var patternHash: String {
        // In a real implementation, this would create a secure hash of the pattern
        // for comparison without storing the raw data
        let dataString = heartRateData.map { String($0) }.joined(separator: ",")
        return dataString.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

// MARK: - Heart Pattern Analysis

extension HeartPattern {
    /// Calculate similarity between two heart patterns
    func similarity(to other: HeartPattern) -> Double {
        guard !heartRateData.isEmpty && !other.heartRateData.isEmpty else { return 0 }
        
        // Simple correlation-based similarity
        // In a real implementation, this would use more sophisticated algorithms
        let minLength = min(heartRateData.count, other.heartRateData.count)
        let truncatedSelf = Array(heartRateData.prefix(minLength))
        let truncatedOther = Array(other.heartRateData.prefix(minLength))
        
        let correlation = calculateCorrelation(truncatedSelf, truncatedOther)
        return max(0, correlation)
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0
    }
}
