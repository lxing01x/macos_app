import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isSidebarVisible = true
    @State private var activeTerminal: Host?
    
    var body: some View {
        NavigationSplitView {
            HostListView(activeTerminal: $activeTerminal)
                .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 400)
        } detail: {
            if let activeTerminal = activeTerminal {
                TerminalView(host: activeTerminal)
                    .navigationTitle(activeTerminal.displayName)
            } else {
                WelcomeView()
                    .navigationTitle("SSH Terminal")
            }
        }
        .sheet(isPresented: $hostManager.showingAddHost) {
            HostEditView(host: nil)
                .frame(width: 500, height: 400)
        }
        .sheet(isPresented: $hostManager.showingEditHost) {
            if let editingHost = hostManager.editingHost {
                HostEditView(host: editingHost)
                    .frame(width: 500, height: 400)
            }
        }
        .background(themeManager.backgroundColor)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    isSidebarVisible.toggle()
                }) {
                    Image(systemName: "sidebar.leading")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        hostManager.showingAddHost = true
                    }) {
                        Label("Add Host", systemImage: "plus")
                    }
                    
                    if let selectedHost = hostManager.selectedHost {
                        Divider()
                        
                        Button(action: {
                            hostManager.startEditing(selectedHost)
                        }) {
                            Label("Edit Host", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            hostManager.deleteHost(selectedHost)
                        }) {
                            Label("Delete Host", systemImage: "trash")
                        }
                    }
                    
                    Divider()
                    
                    Menu("Theme") {
                        Button(action: {
                            themeManager.currentTheme = AppTheme.light
                        }) {
                            Label("Light Mode", systemImage: themeManager.currentTheme == AppTheme.light ? "checkmark" : "")
                        }
                        
                        Button(action: {
                            themeManager.currentTheme = AppTheme.dark
                        }) {
                            Label("Dark Mode", systemImage: themeManager.currentTheme == AppTheme.dark ? "checkmark" : "")
                        }
                        
                        Button(action: {
                            themeManager.toggleTheme()
                        }) {
                            Label("Toggle Theme", systemImage: "switch.2")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "terminal")
                .font(.system(size: 80))
                .foregroundColor(themeManager.accentColor)
            
            Text("SSH Terminal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("Connect to your servers and manage your infrastructure")
                .font(.title3)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Button(action: {
                    hostManager.showingAddHost = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Your First Host")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(themeManager.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("or")
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Button(action: {
                    // Quick connect action
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Quick Connect")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(themeManager.selectionColor)
                    .foregroundColor(themeManager.textColor)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HostManager())
            .environmentObject(ThemeManager())
    }
}
#endif
