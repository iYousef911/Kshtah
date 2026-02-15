//
//  CrowdService.swift
//  Kashat
//
//  Created by AI Assistant on 15/02/2026.
//

import Foundation
import CoreLocation
import WeatherKit

struct CrowdPrediction {
    let score: Int // 0 to 100
    let label: String
    let colorHex: String
}

class CrowdService {
    static let shared = CrowdService()
    
    // "AI" Logic to predict crowdednesswhat elswe
    func predictCrowd(for spot: CampingSpot, weather: Weather?) -> CrowdPrediction {
        var score = 50 // Base score
        
        // 1. Time Factor (Weekend = Crowded)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = (weekday == 6 || weekday == 7) // Friday/Saturday in Saudi
        
        if isWeekend {
            score += 30
        } else {
            score -= 20
        }
        
        // 2. Weather Factor (Nice weather = Crowded)
        if let w = weather {
            let temp = w.currentWeather.temperature.value
            if temp > 15 && temp < 30 {
                score += 20 // Ideal camping weather
            } else if temp > 35 || temp < 5 {
                score -= 30 // Too hot/cold
            }
        }
        
        // 3. Popularity (Rating)
        if spot.rating > 4.5 {
            score += 10
        }
        
        // 4. Determinstic Noise (to simulate real-world variance)
        // Use hash of ID to add -10 to +10 range
        let hash = abs(spot.id.hashValue) % 20
        score += (hash - 10)
        
        // Clamp
        score = max(0, min(100, score))
        
        // Determine Label
        if score >= 75 { // Slightly higher threshold for Red
            return CrowdPrediction(score: score, label: "مزدحم جداً", colorHex: "#FF0000") // Red
        } else if score >= 45 {
            return CrowdPrediction(score: score, label: "متوسط", colorHex: "#FFA500") // Orange
        } else {
            return CrowdPrediction(score: score, label: "هادئ", colorHex: "#00FF00") // Green
        }
    }
}
