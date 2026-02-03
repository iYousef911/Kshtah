import Foundation

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
        let newMoonReference = Date(timeIntervalSince1970: 1704944400) // Jan 11 2024 New Moon
        
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
        case 0...0.05, 0.95...1.0:
            return ("محاق (جديد)", "moonphase.new.moon")
        case 0.05...0.2:
            return ("هلال متزايد", "moonphase.waxing.crescent")
        case 0.2...0.3:
            return ("تربيع أول", "moonphase.first.quarter")
        case 0.3...0.45:
            return ("أحدب متزايد", "moonphase.waxing.gibbous")
        case 0.45...0.55:
            return ("بدر (مكتمل)", "moonphase.full.moon")
        case 0.55...0.7:
            return ("أحدب متناقص", "moonphase.waning.gibbous")
        case 0.7...0.8:
            return ("تربيع أخير", "moonphase.last.quarter")
        case 0.8...0.95:
            return ("هلال متناقص", "moonphase.waning.crescent")
        default:
            return ("خسوف", "moon")
        }
    }
}
