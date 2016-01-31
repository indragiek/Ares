//
//  ConnectionManager.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(manager: ConnectionManager, didUpdateDevices devices: [Device])
    func connectionManager(manager: ConnectionManager, didFailWithError error: NSError)
}

public struct Device: CustomStringConvertible {
    public enum Availability {
        case None
        case Local
        case Remote
    }
    
    public var description: String {
        return "Device{registeredDevice=\(registeredDevice), availability=\(availability)}"
    }
    
    public let registeredDevice: RegisteredDevice
    public let availability: Availability
}

private let ServiceType = "ares-ft";
private let DiscoveryUUIDKey = "uuid";

@objc public final class ConnectionManager: NSObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let client: Client
    private let token: AccessToken
    private let localPeer: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private var peerIDToUUIDMap = [MCPeerID: String]()
    
    private(set) public var devices = [Device]() {
        didSet {
            delegate?.connectionManager(self, didUpdateDevices: devices)
        }
    }
    
    public weak var delegate: ConnectionManagerDelegate?
    
    public init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
        
        localPeer = MCPeerID(displayName: getDeviceName())
        session = MCSession(peer: localPeer)
        let discoveryInfo = [DiscoveryUUIDKey: client.deviceUUID]
        advertiser = MCNearbyServiceAdvertiser(peer: localPeer, discoveryInfo: discoveryInfo, serviceType: ServiceType)
        browser = MCNearbyServiceBrowser(peer: localPeer, serviceType: ServiceType)
        
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
    }
    
    public func getDeviceList(completionHandler: Void -> Void) {
        client.getDevices(token) { result in
            switch result {
            case let .Success(registeredDevices):
                self.devices = registeredDevices
                    .filter {
                        return $0.uuid != self.client.deviceUUID
                    }.map {
                        Device(registeredDevice: $0, availability: .None)
                    }
                completionHandler()
            case let .Failure(error):
                self.delegate?.connectionManager(self, didFailWithError: error)
            }
        }
    }
    
    public func startMonitoring() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    public func stopMonitoring() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    // MARK: MCNearbyServiceAdvertiserDelegate
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        delegate?.connectionManager(self, didFailWithError: error)
    }
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
    }
    
    // MARK: MCNearbyServiceBrowserDelegate
    
    public func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        delegate?.connectionManager(self, didFailWithError: error)
    }
    
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let uuid = info?[DiscoveryUUIDKey] else { return }
        guard let (index, device) = findDeviceWithUUID(uuid) else { return }
        
        peerIDToUUIDMap[peerID] = uuid
        let newDevice = Device(registeredDevice: device.registeredDevice, availability: .Local)
        devices[index] = newDevice
    }
    
    public func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let uuid = peerIDToUUIDMap[peerID] else { return }
        guard let (index, device) = findDeviceWithUUID(uuid) else { return }
        
        peerIDToUUIDMap.removeValueForKey(peerID)
        let newDevice = Device(registeredDevice: device.registeredDevice, availability: .None)
        devices[index] = newDevice
    }
    
    private func findDeviceWithUUID(uuid: String) -> (Int, Device)? {
        for (index, device) in devices.enumerate() {
            if device.registeredDevice.uuid == uuid {
                return (index, device)
            }
        }
        return nil
    }
}
