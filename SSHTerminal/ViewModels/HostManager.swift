import Foundation
import Combine

class HostManager: ObservableObject {
    @Published var hosts: [Host] = []
    @Published var selectedHost: Host?
    @Published var showingAddHost = false
    @Published var showingEditHost = false
    @Published var editingHost: Host?
    
    private let saveKey = "SavedHosts"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHosts()
        
        $hosts
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] hosts in
                self?.saveHosts()
            }
            .store(in: &cancellables)
    }
    
    func loadHosts() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            hosts = try decoder.decode([Host].self, from: data)
        } catch {
            print("Error loading hosts: \(error)")
            hosts = []
        }
    }
    
    func saveHosts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(hosts)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving hosts: \(error)")
        }
    }
    
    func addHost(_ host: Host) {
        hosts.append(host)
    }
    
    func updateHost(_ updatedHost: Host) {
        guard let index = hosts.firstIndex(where: { $0.id == updatedHost.id }) else {
            return
        }
        hosts[index] = updatedHost
    }
    
    func deleteHost(_ host: Host) {
        hosts.removeAll { $0.id == host.id }
        if selectedHost == host {
            selectedHost = nil
        }
    }
    
    func updateLastConnected(for host: Host) {
        guard let index = hosts.firstIndex(where: { $0.id == host.id }) else {
            return
        }
        hosts[index].lastConnected = Date()
    }
    
    func startEditing(_ host: Host) {
        editingHost = host
        showingEditHost = true
    }
}
