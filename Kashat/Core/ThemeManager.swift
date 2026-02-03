import SwiftUI
internal import Combine

enum AppTheme: String, CaseIterable {
    case standard = "Standard"
    case foundingDay = "Founding Day"
    
    var primaryColor: Color {
        switch self {
        case .standard:
            return .blue
        case .foundingDay:
            return Color(red: 0.29, green: 0.22, blue: 0.16) // Official Coffee/Brown (#4A3728)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .standard:
            return [.black, Color(red: 0.05, green: 0.08, blue: 0.12), .black]
        case .foundingDay:
            return [
                Color(red: 0.96, green: 0.94, blue: 0.88), // Creamy Sand (#F5F0E1)
                Color(red: 0.05, green: 0.24, blue: 0.15), // Heritage Green (#0C3E26)
                Color(red: 0.29, green: 0.22, blue: 0.16)  // Coffee Brown
            ]
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.foundingDay.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .foundingDay
    }
}
