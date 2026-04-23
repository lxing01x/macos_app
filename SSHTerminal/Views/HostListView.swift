import SwiftUI

struct HostListView: View {
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var activeTerminal: Host?
    @State private var searchText = ""
    
    private var filteredHosts: [Host] {
        if searchText.isEmpty {
            return hostManager.hosts
        } else {
            return hostManager.hosts.filter { host in
                host.name.localizedCaseInsensitiveContains(searchText) ||
                host.address.localizedCaseInsensitiveContains(searchText) ||
                host.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack {
                    Text("Hosts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Button(action: {
                        hostManager.showingAddHost = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search hosts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(themeManager.textColor)
                }
                .padding(8)
                .background(themeManager.selectionColor)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(themeManager.backgroundColor)
            
            Divider()
                .background(themeManager.borderColor)
            
            if filteredHosts.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("No hosts found")
                        .font(.headline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    if searchText.isEmpty {
                        Button(action: {
                            hostManager.showingAddHost = true
                        }) {
                            Text("Add your first host")
                                .font(.subheadline)
                                .foregroundColor(themeManager.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(themeManager.backgroundColor)
            } else {
                List {
                    ForEach(filteredHosts) { host in
                        HostRowView(host: host, activeTerminal: $activeTerminal)
                            .listRowBackground(
                                hostManager.selectedHost?.id == host.id ? 
                                    themeManager.selectionColor : themeManager.backgroundColor
                            )
                            .onTapGesture {
                                hostManager.selectedHost = host
                            }
                            .contextMenu {
                                Button(action: {
                                    activeTerminal = host
                                    hostManager.updateLastConnected(for: host)
                                }) {
                                    Label("Connect", systemImage: "arrow.right.circle")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    hostManager.startEditing(host)
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    hostManager.deleteHost(host)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .background(themeManager.backgroundColor)
            }
        }
        .background(themeManager.backgroundColor)
    }
}

struct HostRowView: View {
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var themeManager: ThemeManager
    let host: Host
    @Binding var activeTerminal: Host?
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(host.displayName)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Text("\(host.username)@\(host.address):\(host.port)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let lastConnected = host.lastConnected {
                Text(timeAgo(from: lastConnected))
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Button(action: {
                activeTerminal = host
                hostManager.updateLastConnected(for: host)
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(themeManager.accentColor)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovered ? 1.0 : 0.6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .background(Color.clear)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct HostListView_Previews: PreviewProvider {
    static var previews: some View {
        HostListView(activeTerminal: .constant(nil))
            .environmentObject(HostManager())
            .environmentObject(ThemeManager())
    }
}
#endif
