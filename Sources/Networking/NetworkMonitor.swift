//
//  NetworkMonitor.swift
//  MyLibrary
//
//  Created by Macbook on 27/10/25.
//

import Network
import SwiftUI
import Network

// MARK: - Network Monitor Class
@available(iOS 13.0, *)
@MainActor
public class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published public var isConnected: Bool = true
    @Published public var connectionType: ConnectionType = .unknown
    @Published public var isVPNActive: Bool = false
    
    public enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wiredEthernet = "Ethernet"
        case unknown = "Unknown"
    }
    
    public init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
                self?.checkVPNStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) { connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) { connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) { connectionType = .wiredEthernet
        } else { connectionType = .unknown }
    }
    
    private func checkVPNStatus(_ path: NWPath) {
        // Check VPN - available interfaces
        let vpnInterfaces = path.availableInterfaces.filter {
            $0.type == .other && ($0.name.contains("utun") || $0.name.contains("ipsec") || $0.name.contains("ppp"))
        }
        isVPNActive = !vpnInterfaces.isEmpty
        
        if !isVPNActive {
            isVPNActive = checkVPNFromSystemProxy()
        }
    }
    
    private func checkVPNFromSystemProxy() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scopes = settings["__SCOPED__"] as? [String: Any] else {
            return false
        }
        
        for (key, _) in scopes {
            if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") {
                return true
            }
        }
        return false
    }
    
    deinit {
        monitor.cancel()
    }
}

@available(iOS 17.0, *)
public struct NoInternetView: View {
    @EnvironmentObject private var monitor: NetworkMonitor
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 80, weight: .semibold))
                .frame(height: 100)
            
            Text("No Internet Connectivity")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Please check your internet connection\nto continue using the app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .lineLimit(2)
            
            Text("Waiting for internet connection...")
                .font(.caption)
                .foregroundStyle(.background)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.primary)
                .padding(.top, 10)
                .padding(.horizontal, -20)
            
        }
        .fontDesign(.rounded)
        .padding([.horizontal, .top], 20)
        .background(.background)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(height: 310)
    }
}





