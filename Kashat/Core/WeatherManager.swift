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
            return weather
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
            return nil
        }
    }
}
