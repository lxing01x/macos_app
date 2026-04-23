import Foundation

struct Host: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var port: Int
    var username: String
    var password: String
    var createdAt: Date
    var lastConnected: Date?
    
    init(id: UUID = UUID(),
         name: String,
         address: String,
         port: Int = 22,
         username: String,
         password: String,
         createdAt: Date = Date(),
         lastConnected: Date? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
        self.username = username
        self.password = password
        self.createdAt = createdAt
        self.lastConnected = lastConnected
    }
    
    var displayName: String {
        return name.isEmpty ? "\(username)@\(address)" : name
    }
    
    var sshCommand: String {
        return "ssh -p \(port) \(username)@\(address)"
    }
    
    static func == (lhs: Host, rhs: Host) -> Bool {
        return lhs.id == rhs.id
    }
}
