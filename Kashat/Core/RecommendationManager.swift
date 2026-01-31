//
//  RecommendationManager.swift
//  Kashat
//
//  Created by AI Assistant on 22/11/2025.
//

import Foundation
import CoreLocation
import WeatherKit

struct RecommendedSpot: Identifiable, Hashable {
    let id = UUID()
    let spot: CampingSpot
    let weatherScore: Double // 0 to 100
    let temperature: Double
    let condition: String
    let smartInsight: String // NEW: AI Generated Text
    
    var tempString: String {
        return String(format: "%.0f°", temperature)
    }
}

class RecommendationManager {
    static let shared = RecommendationManager()
    private let weatherManager = WeatherManager.shared
    
    // Analyze and rank spots based on upcoming weekend weather
    // If userLocation is provided, prioritizes spots within 400km
    func getWeekendRecommendations(spots: [CampingSpot], userLocation: CLLocation?) async -> [RecommendedSpot] {
        // 1. Filter by Distance (if location known)
        let spotsToScore: [CampingSpot]
        
        if let userLoc = userLocation {
            let maxDistance: CLLocationDistance = 400_000 // 400km in meters
            
            let nearbySpots = spots.filter { spot in
                let spotLoc = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
                return spotLoc.distance(from: userLoc) <= maxDistance
            }
            
            // If we have nearby spots, focus on them. Otherwise, fallback to all.
            spotsToScore = nearbySpots.isEmpty ? spots : nearbySpots
        } else {
            spotsToScore = spots
        }
        
        var scoredSpots: [RecommendedSpot] = []
        
        // For simple demo, we check CURRENT weather.
        // In production, we'd calculate the date for next Friday.
        
        for spot in spotsToScore {
            if let weather = await weatherManager.getWeather(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude) {
                
                let currentTemp = weather.currentWeather.temperature.value
                let condition = weather.currentWeather.condition
                let wind = weather.currentWeather.wind.speed.value
                
                // --- Granular Scoring Logic 2.0 ---
                // Start with perfect 100 and subtract based on deviation from ideal (24°C)
                var score: Double = 100.0
                
                // 1. Temperature Factor (Ideal: 24°C)
                // Lose 2.5 points for every degree away from 24
                let idealTemp = 24.0
                let tempDiff = abs(currentTemp - idealTemp)
                score -= (tempDiff * 2.5)
                
                // 2. Wind Factor
                // Lose 0.5 points for every km/h of wind
                score -= (wind * 0.5)
                
                // 3. Condition Factor
                switch condition {
                case .clear, .mostlyClear:
                    score += 2   // Slight bonus for stars
                case .partlyCloudy:
                    score -= 0   // Neutral
                case .cloudy, .mostlyCloudy:
                    score -= 5   // Less scenic
                case .rain, .drizzle:
                    score -= 30  // Wet ground
                case .heavyRain, .thunderstorms, .strongStorms:
                    score -= 60  // Dangerous
                default:
                    score -= 10
                }
                
                // Cap score between 0 and 100
                score = max(0, min(100, score))
                
                // Create intermediate object without insight logic yet
                let rec = RecommendedSpot(
                    spot: spot,
                    weatherScore: max(0, min(100, score)),
                    temperature: currentTemp,
                    condition: condition.description,
                    smartInsight: "جاري التحليل..." // Placeholder
                )
                
                scoredSpots.append(rec)
            }
        }
        
        // Sort and pick top 3
        let topSpots = scoredSpots.sorted { $0.weatherScore > $1.weatherScore }.prefix(3)
        
        // Generate AI Insights ONLY for the top 3 (to save cost/time)
        var finalRecommendations: [RecommendedSpot] = []
        
        for var rec in topSpots {
            // Call AI Service
            let insight = await AIService.shared.generateInsight(
                spotName: rec.spot.name,
                location: rec.spot.location,
                temperature: rec.temperature,
                condition: rec.condition
            )
            
            // Create new struct with AI text
            let updatedRec = RecommendedSpot(
                spot: rec.spot,
                weatherScore: rec.weatherScore,
                temperature: rec.temperature,
                condition: rec.condition,
                smartInsight: insight
            )
            finalRecommendations.append(updatedRec)
        }

        return finalRecommendations
    }
}
