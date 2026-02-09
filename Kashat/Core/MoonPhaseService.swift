import Foundation
import WeatherKit

struct MoonPhase {
    let phase: Double // 0 to 1
    let name: String
    let icon: String // SF Symbol
    let illumination: Int // percentage
    
    var isDark: Bool {
        return illumination < 30 // Good for stargazing
    }
}

class MoonPhaseService {
    static let shared = MoonPhaseService()
    
    func getMoonPhase(for date: Date = Date()) -> MoonPhase {
        // Very simplified Julian Day Calculation for Moon Phase
        let lp = 2551443.0 // Lunar period in seconds
        let newMoonReference = Date(timeIntervalSince1970: 1704974220) // Jan 11 2024 11:57 UTC
        
        let secondsSinceNewMoon = date.timeIntervalSince(newMoonReference)
        let phase = (secondsSinceNewMoon.truncatingRemainder(dividingBy: lp)) / lp
        
        let normalizedPhase = phase < 0 ? phase + 1 : phase
        
        let illumination: Int
        if normalizedPhase <= 0.5 {
            illumination = Int(normalizedPhase * 200)
        } else {
            illumination = Int((1 - normalizedPhase) * 200)
        }
        
        let (name, icon) = moonDetails(for: normalizedPhase)
        
        return MoonPhase(phase: normalizedPhase, name: name, icon: icon, illumination: illumination)
    }
    
    private func moonDetails(for phase: Double) -> (String, String) {
        switch phase {
        case 0...0.04, 0.96...1.0:
            return ("محاق (جديد)", "moonphase.new.moon")
        case 0.04...0.22:
            return ("هلال متزايد", "moonphase.waxing.crescent")
        case 0.22...0.28:
            return ("تربيع أول", "moonphase.first.quarter")
        case 0.28...0.44:
            return ("أحدب متزايد", "moonphase.waxing.gibbous")
        case 0.44...0.56:
            return ("بدر (مكتمل)", "moonphase.full.moon")
        case 0.56...0.72:
            return ("أحدب متناقص", "moonphase.waning.gibbous")
        case 0.72...0.78:
            return ("تربيع أخير", "moonphase.last.quarter")
        case 0.78...0.96:
            return ("هلال متناقص", "moonphase.waning.crescent")
        default:
            return ("بدر (مكتمل)", "moonphase.full.moon")
        }
    }
    
    // Mapping Apple's WeatherKit MoonPhase to our model
    func mapWeatherKitPhase(_ phase: WeatherKit.MoonPhase) -> (String, String) {
        switch phase {
        case .new: return ("محاق (جديد)", "moonphase.new.moon")
        case .waxingCrescent: return ("هلال متزايد", "moonphase.waxing.crescent")
        case .firstQuarter: return ("تربيع أول", "moonphase.first.quarter")
        case .waxingGibbous: return ("أحدب متزايد", "moonphase.waxing.gibbous")
        case .full: return ("بدر (مكتمل)", "moonphase.full.moon")
        case .waningGibbous: return ("أحدب متناقص", "moonphase.waning.gibbous")
        case .lastQuarter: return ("تربيع أخير", "moonphase.last.quarter")
        case .waningCrescent: return ("هلال متناقص", "moonphase.waning.crescent")
        @unknown default: return ("بدر (مكتمل)", "moonphase.full.moon")
        }
    }
}
