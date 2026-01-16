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
    func getWeekendRecommendations(spots: [CampingSpot]) async -> [RecommendedSpot] {
        var scoredSpots: [RecommendedSpot] = []
        
        // For simple demo, we check CURRENT weather. 
        // In production, we'd calculate the date for next Friday.
        
        for spot in spots {
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
                
                // --- AI Insight Generation ---
                var insight = ""
                if currentTemp >= 20 && currentTemp <= 28 && wind < 15 {
                    insight = "الجو ممتاز! درجة حرارة معتدلة (\(Int(currentTemp))°) ورياح هادئة، مكان مثالي للكشتة."
                } else if currentTemp < 15 {
                    insight = "الجو بارد قليلاً (\(Int(currentTemp))°). تأكد من إحضار ملابس دافئة وفروة!"
                } else if currentTemp > 35 {
                    insight = "الجو حار (\(Int(currentTemp))°). الأفضل للكشتات المسائية."
                } else if wind > 25 {
                    insight = "رياح نشطة (\(Int(wind)) كم/س). تأكد من تثبيت الخيمة جيداً."
                } else if condition == .clear {
                    insight = "سماء صافية الليلة! فرصة ممتازة لتأمل النجوم بعيداً عن أضواء المدينة."
                } else {
                    insight = "الأجواء مستقرة. خيار جيد لطلعة سريعة."
                }
                
                // Create Recommendation
                let rec = RecommendedSpot(
                    spot: spot,
                    weatherScore: max(0, min(100, score)),
                    temperature: currentTemp,
                    condition: condition.description,
                    smartInsight: insight
                )
                
                scoredSpots.append(rec)
            }
        }
        
        // Return top 3 sorted by score
        return scoredSpots.sorted { $0.weatherScore > $1.weatherScore }.prefix(3).map { $0 }
    }
}
