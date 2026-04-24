import Foundation
import Combine

class SSHService: ObservableObject {
    @Published var isConnected = false
    @Published var output = ""
    @Published var errorMessage = ""
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()
    
    func connect(to host: Host) {
        disconnect()
        
        if !host.password.isEmpty {
            output = "[Notice: Built-in terminal may not support password authentication. Please use 'Open in System Terminal' for password-based connections, or use SSH key authentication.]\n"
            output += "[Connecting to \(host.username)@\(host.address):\(host.port)]\n"
        } else {
            output = "[Connecting to \(host.username)@\(host.address):\(host.port)]\n"
        }
        
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        if !host.password.isEmpty {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/expect")
            
            let escapedPassword = host.password
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "[", with: "\\[")
                .replacingOccurrences(of: "]", with: "\\]")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
            
            let expectScript = """
            set timeout -1
            spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p \(host.port) \(host.username)@\(host.address)
            expect {
                "assword:" {
                    send "\(escapedPassword)\\r"
                    exp_continue
                }
                "yes/no" {
                    send "yes\\r"
                    exp_continue
                }
                eof {
                    exit
                }
            }
            interact
            """
            
            process.arguments = ["-c", expectScript]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            
            let arguments = [
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-p", "\(host.port)",
                "\(host.username)@\(host.address)"
            ]
            
            process.arguments = arguments
        }
        
        self.process = process
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.output += string
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.errorMessage += string
                    self?.output += string
                }
            }
        }
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.output += "\n[Connection closed]\n"
            }
        }
        
        do {
            try process.run()
            isConnected = true
            
            if host.password.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.sendInput("\n")
                }
            }
        } catch {
            errorMessage = "Failed to start SSH: \(error.localizedDescription)"
            output = "[Error: \(error.localizedDescription)]\n"
        }
    }
    
    func connectInTerminal(to host: Host) {
        let script = """
        tell application "Terminal"
            launch
            activate
            delay 0.2
            do script "ssh -o StrictHostKeyChecking=no -p \(host.port) \(host.username)@\(host.address)"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript error: \(error)")
                let fallbackScript = """
                tell application "System Events"
                    set terminalIsRunning to (name of processes) contains "Terminal"
                end tell
                
                if terminalIsRunning is false then
                    tell application "Terminal"
                        launch
                        activate
                    end tell
                    delay 0.5
                end if
                
                tell application "Terminal"
                    activate
                    do script "ssh -o StrictHostKeyChecking=no -p \(host.port) \(host.username)@\(host.address)"
                end tell
                """
                if let fallbackAppleScript = NSAppleScript(source: fallbackScript) {
                    var fallbackError: NSDictionary?
                    fallbackAppleScript.executeAndReturnError(&fallbackError)
                    if let fallbackError = fallbackError {
                        print("Fallback AppleScript error: \(fallbackError)")
                    }
                }
            }
        }
    }
    
    func sendInput(_ input: String) {
        guard let inputPipe = inputPipe, isConnected else { return }
        
        if let data = input.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }
    
    func disconnect() {
        process?.terminate()
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        isConnected = false
    }
    
    deinit {
        disconnect()
    }
}
