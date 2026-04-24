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
        
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        
        let arguments = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-p", "\(host.port)",
            "\(host.username)@\(host.address)"
        ]
        
        process.arguments = arguments
        
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
            output = "[Connecting to \(host.username)@\(host.address):\(host.port)]\n"
            
            if !host.password.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.sendInput(host.password + "\n")
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
            activate
            do script "ssh -o StrictHostKeyChecking=no -p \(host.port) \(host.username)@\(host.address)"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript error: \(error)")
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
