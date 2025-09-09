import SwiftUI
import WatchConnectivity

struct DeviceManagementView: View {
    @StateObject private var deviceManager = DeviceManager()
    private let colors = HeartIDColors()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connected Devices Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Connected Devices")
                        .font(.headline)
                    
                    ForEach(deviceManager.connectedDevices) { device in
                        DeviceCard(device: device)
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Available Devices Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Devices")
                        .font(.headline)
                    
                    if deviceManager.availableDevices.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(colors.text.opacity(0.6))
                            Text("Searching for devices...")
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                        .padding()
                    } else {
                        ForEach(deviceManager.availableDevices) { device in
                            Button(action: { deviceManager.connect(device) }) {
                                DeviceCard(device: device)
                            }
                        }
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(colors.background)
        .navigationTitle("Devices")
    }
}

// MARK: - Device Card
struct DeviceCard: View {
    let device: ConnectedDevice
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: device.icon)
                .foregroundColor(colors.accent)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.subheadline)
                Text(device.status.rawValue)
                    .font(.caption)
                    .foregroundColor(device.status.color)
            }
            
            Spacer()
            
            if device.status == .connected {
                Menu {
                    Button(role: .destructive, action: {}) {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                    Button(action: {}) {
                        Label("Rename", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(colors.text)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Device Manager
class DeviceManager: ObservableObject {
    @Published var connectedDevices: [ConnectedDevice] = []
    @Published var availableDevices: [ConnectedDevice] = []
    
    init() {
        // Mock data
        connectedDevices = [
            ConnectedDevice(id: "1", name: "Apple Watch Series 9", type: .appleWatch, status: .connected),
            ConnectedDevice(id: "2", name: "Oura Ring Gen3", type: .appleWatch, status: .connected)
        ]
        
        availableDevices = [
            ConnectedDevice(id: "3", name: "Galaxy Watch 6", type: .appleWatch, status: .available)
        ]
    }
    
    func connect(_ device: ConnectedDevice) {
        // Implement connection logic
    }
}

// MARK: - Models
struct ConnectedDevice: Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    var status: DeviceStatus
    
    var icon: String {
        switch type {
        case .appleWatch: return "applewatch"
        case .bluetoothDoorLock: return "lock"
        case .nfcTag: return "wave.3.right"
        case .enterpriseDevice: return "building.2"
        }
    }
}


enum DeviceStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case available = "Available"
    case pairing = "Pairing..."
    
    var color: Color {
        let colors = HeartIDColors()
        switch self {
        case .connected: return colors.success
        case .disconnected: return colors.error
        case .available: return colors.text.opacity(0.6)
        case .pairing: return colors.warning
        }
    }
}

#Preview {
    DeviceManagementView()
}
