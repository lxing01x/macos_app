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
        
        output = "[Connecting to \(host.username)@\(host.address):\(host.port)]\n"
        
        if !host.password.isEmpty {
            output += "[Notice: Built-in terminal may have issues with password authentication. If connection fails, please use 'Open in System Terminal'.]\n"
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
                .replacingOccurrences(of: "`", with: "\\`")
            
            let expectScript = """
            set timeout 30
            spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p \(host.port) \(host.username)@\(host.address)
            expect {
                -re "assword:" {
                    send "\(escapedPassword)\\r"
                    exp_continue
                }
                -re "yes/no" {
                    send "yes\\r"
                    exp_continue
                }
                -re "Permission denied" {
                    puts "Permission denied - Please check your password or use System Terminal."
                    exit 1
                }
                -re "\\$|#|%|>" {
                    puts "Connected successfully!"
                }
                timeout {
                    puts "Connection timed out."
                    exit 1
                }
                eof {
                    puts "Connection closed."
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
        } catch {
            errorMessage = "Failed to start SSH: \(error.localizedDescription)"
            output = "[Error: \(error.localizedDescription)]\n"
        }
    }
    
    func connectInTerminal(to host: Host) {
        let sshCommand = "ssh -o StrictHostKeyChecking=no -p \(host.port) \(host.username)@\(host.address)"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let workspace = NSWorkspace.shared
            
            if !workspace.launchApplication("Terminal") {
                let terminalURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
                try? workspace.open(terminalURL)
            }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            let script = """
            tell application "Terminal"
                activate
                do script "\(sshCommand)"
            end tell
            """
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    print("AppleScript error: \(error)")
                    
                    let fallbackScript = """
                    do shell script "open -a Terminal.app"
                    delay 1
                    tell application "Terminal"
                        activate
                        do script "\(sshCommand)"
                    end tell
                    """
                    
                    var fallbackError: NSDictionary?
                    if let fallbackAppleScript = NSAppleScript(source: fallbackScript) {
                        fallbackAppleScript.executeAndReturnError(&fallbackError)
                        if let fallbackError = fallbackError {
                            print("Fallback AppleScript error: \(fallbackError)")
                            
                            let shellScript = "osascript -e 'tell application \"Terminal\" to activate' -e 'tell application \"Terminal\" to do script \"\(sshCommand)\"'"
                            
                            let task = Process()
                            task.launchPath = "/bin/bash"
                            task.arguments = ["-c", shellScript]
                            
                            do {
                                try task.run()
                            } catch {
                                print("Shell script error: \(error)")
                            }
                        }
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
