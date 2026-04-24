import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var sshService = SSHService()
    let host: Host
    
    @State private var inputText = ""
    @State private var showConnectionOptions = false
    @State private var connectionMethod: ConnectionMethod
    @FocusState private var isInputFocused: Bool
    
    enum ConnectionMethod {
        case systemTerminal
        case builtInTerminal
    }
    
    init(host: Host) {
        self.host = host
        if host.password.isEmpty {
            _connectionMethod = State(initialValue: .builtInTerminal)
        } else {
            _connectionMethod = State(initialValue: .systemTerminal)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                connectionStatusBar
                
                Spacer()
                
                HStack(spacing: 10) {
                    Menu {
                        Button(action: {
                            connectionMethod = .systemTerminal
                            connect()
                        }) {
                            Label("Open in System Terminal", systemImage: "terminal")
                        }
                        
                        Button(action: {
                            connectionMethod = .builtInTerminal
                            connect()
                        }) {
                            Label("Use Built-in Terminal", systemImage: "laptopcomputer")
                        }
                    } label: {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(themeManager.accentColor)
                    }
                    .help("Connect using different methods")
                    
                    if sshService.isConnected {
                        Button(action: {
                            sshService.disconnect()
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .help("Disconnect")
                    }
                    
                    Menu {
                        Button(action: {
                            if let data = sshService.output.data(using: .utf8) {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setData(data, forType: .string)
                            }
                        }) {
                            Label("Copy All Output", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            sshService.output = ""
                        }) {
                            Label("Clear Terminal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(themeManager.backgroundColor)
            
            Divider()
                .background(themeManager.borderColor)
            
            if connectionMethod == .builtInTerminal {
                builtInTerminalView
            } else {
                systemTerminalPromptView
            }
        }
        .background(themeManager.backgroundColor)
        .onAppear {
            connect()
        }
        .onDisappear {
            sshService.disconnect()
        }
    }
    
    private var connectionStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(sshService.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(sshService.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text(host.displayName)
                .font(.caption)
                .foregroundColor(themeManager.textColor)
                .fontWeight(.medium)
        }
    }
    
    private var systemTerminalPromptView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "terminal")
                .font(.system(size: 80))
                .foregroundColor(themeManager.accentColor)
            
            VStack(spacing: 10) {
                if !host.password.isEmpty {
                    Text("Recommended: Use System Terminal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Password authentication works best with System Terminal")
                        .font(.title3)
                        .foregroundColor(themeManager.secondaryTextColor)
                } else {
                    Text("Open in System Terminal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                }
                
                Text("\(host.username)@\(host.address):\(host.port)")
                    .font(.title3)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    sshService.connectInTerminal(to: host)
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Open in Terminal")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(themeManager.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    connectionMethod = .builtInTerminal
                    connect()
                }) {
                    HStack {
                        Image(systemName: "laptopcomputer")
                        Text("Use Built-in Terminal")
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
            
            if !host.password.isEmpty {
                Text("Tip: System Terminal provides full SSH functionality including interactive password prompts. Built-in terminal may have issues with password authentication.")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Tip: Both methods work well for SSH key authentication.")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .background(themeManager.backgroundColor)
    }
    
    private var builtInTerminalView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(sshService.output)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(themeManager.terminalTextColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                        .id("terminalOutput")
                }
                .onChange(of: sshService.output) { _ in
                    withAnimation {
                        proxy.scrollTo("terminalOutput", anchor: .bottom)
                    }
                }
                .background(themeManager.terminalBackgroundColor)
            }
            
            Divider()
                .background(themeManager.borderColor)
            
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.accentColor)
                    .font(.system(size: 12, weight: .bold))
                
                TextField("Type command and press Enter...", text: $inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(themeManager.terminalTextColor)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendCommand()
                    }
                
                Button(action: {
                    sendCommand()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(inputText.isEmpty ? themeManager.secondaryTextColor : themeManager.accentColor)
                }
                .disabled(inputText.isEmpty || !sshService.isConnected)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(themeManager.backgroundColor)
        }
    }
    
    private func connect() {
        if connectionMethod == .builtInTerminal {
            sshService.connect(to: host)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
    
    private func sendCommand() {
        guard !inputText.isEmpty else { return }
        
        sshService.sendInput(inputText + "\n")
        inputText = ""
        isInputFocused = true
    }
}

#if DEBUG
struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalView(host: Host(
            name: "Test Server",
            address: "192.168.1.1",
            port: 22,
            username: "user",
            password: "password"
        ))
        .environmentObject(ThemeManager())
    }
}
#endif
