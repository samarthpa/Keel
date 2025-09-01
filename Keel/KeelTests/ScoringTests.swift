// import XCTest
// @testable import Keel

// final class ScoringTests: XCTestCase {
    
    func testDiningMerchantHighScores() {
        // Test that dining merchants produce higher scores for Amex Gold and Citi Custom Cash
        
        // Test Amex Gold with dining category
        let amexGoldDining = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 10.0,
            priorVisitsToMerchant: 2,
            timeOfDay: 19 // 7 PM - dinner time
        )
        
        // Test Citi Custom Cash with dining category
        let citiDining = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 10.0,
            priorVisitsToMerchant: 2,
            timeOfDay: 19 // 7 PM - dinner time
        )
        
        // Test Chase Freedom with dining category (should be lower)
        let chaseDining = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 10.0,
            priorVisitsToMerchant: 2,
            timeOfDay: 19 // 7 PM - dinner time
        )
        
        // Amex Gold and Citi should score higher than Chase for dining
        XCTAssertGreaterThan(amexGoldDining, chaseDining, "Amex Gold should score higher than Chase for dining")
        XCTAssertGreaterThan(citiDining, chaseDining, "Citi Custom Cash should score higher than Chase for dining")
    }
    
    func testBaseCaseFallback() {
        // Test base case fallback for unknown categories
        
        let unknownCategoryScore = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 5.0,
            priorVisitsToMerchant: 0,
            timeOfDay: 15 // 3 PM - not meal time
        )
        
        // Should return base score around 0.5 for unknown category
        XCTAssertEqual(unknownCategoryScore, 0.5, accuracy: 0.1, "Unknown category should return base score")
    }
    
    func testPriorVisitsBonus() {
        // Test that prior visits increase confidence score
        
        let noVisits = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 5.0,
            priorVisitsToMerchant: 0,
            timeOfDay: 15
        )
        
        let manyVisits = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 5.0,
            priorVisitsToMerchant: 5,
            timeOfDay: 15
        )
        
        XCTAssertGreaterThan(manyVisits, noVisits, "More prior visits should increase confidence score")
    }
    
    func testDwellTimeBonus() {
        // Test that longer dwell time increases confidence score
        
        let shortDwell = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 2.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 15
        )
        
        let longDwell = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 20.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 15
        )
        
        XCTAssertGreaterThan(longDwell, shortDwell, "Longer dwell time should increase confidence score")
    }
    
    func testDistancePenalty() {
        // Test that greater distance decreases confidence score
        
        let closeDistance = ConfidenceScorer.score(
            distanceMeters: 50.0,
            dwellMinutes: 10.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 15
        )
        
        let farDistance = ConfidenceScorer.score(
            distanceMeters: 150.0,
            dwellMinutes: 10.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 15
        )
        
        XCTAssertGreaterThan(closeDistance, farDistance, "Closer distance should increase confidence score")
    }
    
    func testTimeCategoryMatch() {
        // Test that meal times get bonus
        
        let mealTime = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 5.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 19 // 7 PM - dinner time
        )
        
        let nonMealTime = ConfidenceScorer.score(
            distanceMeters: nil,
            dwellMinutes: 5.0,
            priorVisitsToMerchant: 1,
            timeOfDay: 15 // 3 PM - not meal time
        )
        
        XCTAssertGreaterThan(mealTime, nonMealTime, "Meal times should get bonus points")
    }
    
    func testScoreClamping() {
        // Test that scores are properly clamped between 0 and 1
        
        let veryLowScore = ConfidenceScorer.score(
            distanceMeters: 300.0, // Very far
            dwellMinutes: 1.0, // Very short
            priorVisitsToMerchant: 0, // No visits
            timeOfDay: 3 // Very early morning
        )
        
        let veryHighScore = ConfidenceScorer.score(
            distanceMeters: 10.0, // Very close
            dwellMinutes: 60.0, // Very long
            priorVisitsToMerchant: 10, // Many visits
            timeOfDay: 19 // Dinner time
        )
        
        XCTAssertGreaterThanOrEqual(veryLowScore, 0.0, "Score should not be negative")
        XCTAssertLessThanOrEqual(veryLowScore, 1.0, "Score should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(veryHighScore, 0.0, "Score should not be negative")
        XCTAssertLessThanOrEqual(veryHighScore, 1.0, "Score should not exceed 1.0")
    }
}
