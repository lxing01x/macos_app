import Foundation
import Combine
import SwiftUI

enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "AppTheme")
            objectWillChange.send()
        }
    }
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "AppTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .dark
        }
    }
    
    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
    
    var isDarkMode: Bool {
        return currentTheme == .dark
    }
    
    var backgroundColor: Color {
        return isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var textColor: Color {
        return isDarkMode ? .white : .black
    }
    
    var secondaryTextColor: Color {
        return isDarkMode ? Color(white: 0.7) : Color(white: 0.3)
    }
    
    var accentColor: Color {
        return Color(red: 0.2, green: 0.6, blue: 1.0)
    }
    
    var terminalBackgroundColor: Color {
        return isDarkMode ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color(red: 0.98, green: 0.98, blue: 1.0)
    }
    
    var terminalTextColor: Color {
        return isDarkMode ? Color(white: 0.9) : Color(white: 0.1)
    }
    
    var selectionColor: Color {
        return isDarkMode ? Color(red: 0.15, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.85, blue: 0.95)
    }
    
    var borderColor: Color {
        return isDarkMode ? Color(white: 0.2) : Color(white: 0.8)
    }
}
