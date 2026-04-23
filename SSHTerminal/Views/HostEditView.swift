import SwiftUI

struct HostEditView: View {
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    let host: Host?
    
    @State private var name = ""
    @State private var address = ""
    @State private var port = 22
    @State private var username = ""
    @State private var password = ""
    
    private var isEditMode: Bool {
        return host != nil
    }
    
    private var isValid: Bool {
        !address.isEmpty && !username.isEmpty
    }
    
    init(host: Host?) {
        self.host = host
        _name = State(initialValue: host?.name ?? "")
        _address = State(initialValue: host?.address ?? "")
        _port = State(initialValue: host?.port ?? 22)
        _username = State(initialValue: host?.username ?? "")
        _password = State(initialValue: host?.password ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditMode ? "Edit Host" : "Add New Host")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(themeManager.backgroundColor)
            
            Divider()
                .background(themeManager.borderColor)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name (Optional)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("My Server", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server Address *")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("192.168.1.1 or example.com", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Port *")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            TextField("22", value: $port, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .foregroundColor(themeManager.textColor)
                                .frame(width: 120)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username *")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("root or username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password (Optional)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Note: Passwords are stored in UserDefaults. For production use, consider using Keychain.")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            
            Divider()
                .background(themeManager.borderColor)
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .frame(minWidth: 80)
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(action: {
                    saveHost()
                }) {
                    Text(isEditMode ? "Save Changes" : "Add Host")
                        .frame(minWidth: 120)
                }
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
            .background(themeManager.backgroundColor)
        }
        .background(themeManager.backgroundColor)
    }
    
    private func saveHost() {
        if let existingHost = host {
            let updatedHost = Host(
                id: existingHost.id,
                name: name,
                address: address,
                port: port,
                username: username,
                password: password,
                createdAt: existingHost.createdAt,
                lastConnected: existingHost.lastConnected
            )
            hostManager.updateHost(updatedHost)
        } else {
            let newHost = Host(
                name: name,
                address: address,
                port: port,
                username: username,
                password: password
            )
            hostManager.addHost(newHost)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    HostEditView(host: nil)
        .environmentObject(HostManager())
        .environmentObject(ThemeManager())
}
