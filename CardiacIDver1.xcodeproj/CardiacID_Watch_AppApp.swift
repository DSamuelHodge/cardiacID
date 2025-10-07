//
//  CardiacID_Watch_AppApp.swift
//  CardiacID_Watch_App
//
//  Watch App Main Entry Point
//

import SwiftUI

@main
struct CardiacID_Watch_AppApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environmentObject(watchConnectivity)
        }
    }
}

struct WatchMainView: View {
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @State private var heartRate: Int = 0
    @State private var isMonitoring = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Heart Rate Display
                VStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("\(heartRate)")
                        .font(.largeTitle.bold())
                    
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Connection Status
                HStack {
                    Circle()
                        .fill(watchConnectivity.isReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(watchConnectivity.isReachable ? "Connected" : "Disconnected")
                        .font(.caption)
                }
                
                // Control Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if isMonitoring {
                            watchConnectivity.stopMonitoring()
                        } else {
                            watchConnectivity.startMonitoring()
                        }
                        isMonitoring.toggle()
                    }) {
                        Label(
                            isMonitoring ? "Stop" : "Start",
                            systemImage: isMonitoring ? "stop.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isMonitoring ? .red : .green)
                    
                    Button("Enroll") {
                        watchConnectivity.startEnrollment()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Auth") {
                        watchConnectivity.sendEntraIDAuthRequest()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("HeartID")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(watchConnectivity.heartRatePublisher) { (rate, _) in
            heartRate = rate
        }
    }
}

#Preview {
    WatchMainView()
        .environmentObject(WatchConnectivityService.shared)
}