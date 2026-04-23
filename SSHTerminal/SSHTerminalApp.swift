import SwiftUI

@main
struct SSHTerminalApp: App {
    @StateObject private var hostManager = HostManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme == AppTheme.dark ? .dark : .light)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Host") {
                    hostManager.showingAddHost = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Theme") {
                Button("Light Mode") {
                    themeManager.currentTheme = AppTheme.light
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Dark Mode") {
                    themeManager.currentTheme = AppTheme.dark
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Divider()
                
                Button("Toggle Theme") {
                    themeManager.toggleTheme()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
    }
}
