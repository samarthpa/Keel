import Foundation

struct ConfidenceScorer {
    
    static func score(
        distanceMeters: Double?,
        dwellMinutes: Double?,
        priorVisitsToMerchant: Int,
        timeOfDay: Int
    ) -> Double {
        var confidence: Double = 0.5 // Start at 0.5
        
        // Prior visits bonus (up to +0.3)
        if priorVisitsToMerchant >= 5 {
            confidence += 0.3
        } else if priorVisitsToMerchant >= 3 {
            confidence += 0.2
        } else if priorVisitsToMerchant >= 1 {
            confidence += 0.1
        }
        
        // Dwell time bonus (up to +0.2)
        if let dwell = dwellMinutes {
            if dwell > 30 {
                confidence += 0.2
            } else if dwell > 15 {
                confidence += 0.15
            } else if dwell > 5 {
                confidence += 0.1
            }
        }
        
        // Distance penalty (up to -0.2)
        if let distance = distanceMeters {
            if distance > 200 {
                confidence -= 0.2
            } else if distance > 120 {
                confidence -= 0.15
            } else if distance > 80 {
                confidence -= 0.1
            }
        }
        
        // Time-category match bonus (+0.05)
        let hour = timeOfDay
        if (hour >= 8 && hour <= 10) || (hour >= 12 && hour <= 14) || (hour >= 18 && hour <= 22) {
            confidence += 0.05 // Dining/meal times
        }
        
        // Clamp to 0...1 range
        return max(0.0, min(1.0, confidence))
    }
}
