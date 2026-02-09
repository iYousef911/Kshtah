//
//  WeatherManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import Foundation
import WeatherKit
import CoreLocation

class WeatherManager {
    static let shared = WeatherManager()
    private let service = WeatherService.shared
    
    // Fetch current weather for a specific location
    func getWeather(latitude: Double, longitude: Double) async -> Weather? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let weather = try await service.weather(for: location)
            checkIfSevere(weather)
            return weather
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func checkIfSevere(_ weather: Weather) {
        let windSpeed = weather.currentWeather.wind.speed.converted(to: .kilometersPerHour).value
        
        // Thresholds for desert sandstorms / high winds (Example: > 40km/h)
        if windSpeed > 40 {
            let alertInfo = ["type": "wind", "speed": Int(windSpeed)] as [String : Any]
            NotificationCenter.default.post(name: NSNotification.Name("SevereWeatherAlert"), object: nil, userInfo: alertInfo)
        }
    }
}
