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
    func connectionManager(manager: ConnectionManager, willBeginIncomingFileTransfer transfer: IncomingFileTransfer)
    func connectionManager(manager: ConnectionManager, willBeginOutgoingFileTransfer transfer: OutgoingFileTransfer)
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
    internal let peerID: MCPeerID?
    
    internal init(registeredDevice: RegisteredDevice, availability: Availability, peerID: MCPeerID? = nil) {
        self.registeredDevice = registeredDevice
        self.availability = availability
        self.peerID = peerID
    }
}

private let ServiceType = "ares-ft";
private let DiscoveryUUIDKey = "uuid";

@objc public final class ConnectionManager: NSObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, IncomingFileTransferDelegate, OutgoingFileTransferDelegate {
    private let client: Client
    private let token: AccessToken
    private let localPeer: MCPeerID
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private var peerIDToUUIDMap = [MCPeerID: String]()
    private var UUIDToPeerIDMap = [String: MCPeerID]()
    private var UUIDToNotificationMap = [String: [PushNotification]]()
    private var activeTransfers = [AnyObject]()
    private var isMonitoring: Bool = false
    
    private(set) public var devices = [Device]() {
        didSet {
            delegate?.connectionManager(self, didUpdateDevices: devices)
        }
    }
    
    public weak var delegate: ConnectionManagerDelegate?
    public weak var incomingFileTransferDelegate: IncomingFileTransferDelegate?
    public weak var outgoingFileTransferDelegate: OutgoingFileTransferDelegate?
    
    public init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
        
        localPeer = MCPeerID(displayName: getDeviceName())
        let discoveryInfo = [DiscoveryUUIDKey: client.deviceUUID]
        advertiser = MCNearbyServiceAdvertiser(peer: localPeer, discoveryInfo: discoveryInfo, serviceType: ServiceType)
        browser = MCNearbyServiceBrowser(peer: localPeer, serviceType: ServiceType)
        
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
        
        #if os(iOS)
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "appWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        nc.addObserver(self, selector: "appDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        #endif
    }
    
    deinit {
        #if os(iOS)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        #endif
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
        isMonitoring = true
    }
    
    public func stopMonitoring() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        isMonitoring = false
    }
    
    public func queueNotification(notification: PushNotification) {
        if let peerID = UUIDToPeerIDMap[notification.deviceUUID] {
            requestTransferFromPeer(peerID, filePath: notification.filePath)
        } else {
            var notifications = UUIDToNotificationMap[notification.deviceUUID] ?? []
            notifications.append(notification)
            UUIDToNotificationMap[notification.deviceUUID] = notifications
        }
    }
    
    // MARK: Notifications
    
    #if os(iOS)
    @objc private func appWillResignActive(notification: NSNotification) {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        peerIDToUUIDMap.removeAll()
        UUIDToPeerIDMap.removeAll()
    }
    
    @objc private func appDidBecomeActive(notification: NSNotification) {
        guard isMonitoring else { return }
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    #endif
    
    // MARK: Transfers
    
    func requestTransferFromPeer(peerID: MCPeerID, filePath: String) {
        let context = FileTransferContext(filePath: filePath)
        let transfer = IncomingFileTransfer(context: context, localPeerID: localPeer, remotePeerID: peerID)
        transfer.delegate = self
        activeTransfers.append(transfer)
        
        delegate?.connectionManager(self, willBeginIncomingFileTransfer: transfer)
                
        browser.invitePeer(peerID, toSession: transfer.session, withContext: context.archive(), timeout: 30)
    }
    
    // MARK: MCNearbyServiceAdvertiserDelegate
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        delegate?.connectionManager(self, didFailWithError: error)
    }
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        guard let context = context.flatMap(FileTransferContext.init) else { return }
        
        let transfer = OutgoingFileTransfer(context: context, localPeerID: localPeer, remotePeerID: peerID)
        transfer.delegate = self
        activeTransfers.append(transfer)
        delegate?.connectionManager(self, willBeginOutgoingFileTransfer: transfer)
        
        invitationHandler(true, transfer.session)
    }
    
    // MARK: MCNearbyServiceBrowserDelegate
    
    public func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        delegate?.connectionManager(self, didFailWithError: error)
    }
    
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let uuid = info?[DiscoveryUUIDKey] else { return }
        guard let (index, device) = findDeviceWithUUID(uuid) else { return }
        
        peerIDToUUIDMap[peerID] = uuid
        UUIDToPeerIDMap[uuid] = peerID
        
        let newDevice = Device(registeredDevice: device.registeredDevice, availability: .Local, peerID: peerID)
        devices[index] = newDevice
        
        if let notifications = UUIDToNotificationMap[uuid] {
            for notification in notifications {
                requestTransferFromPeer(peerID, filePath: notification.filePath)
            }
        }
    }
    
    public func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let uuid = peerIDToUUIDMap[peerID] else { return }
        guard let (index, device) = findDeviceWithUUID(uuid) else { return }
        
        peerIDToUUIDMap.removeValueForKey(peerID)
        UUIDToPeerIDMap.removeValueForKey(uuid)
        
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
    
    private func removeActiveTransfer(transfer: AnyObject) {
        if let index = activeTransfers.indexOf({ $0 === transfer }) {
            activeTransfers.removeAtIndex(index)
        }
    }
    
    // MARK: IncomingFileTransferDelegate
    
    public func incomingFileTransfer(transfer: IncomingFileTransfer, didReceiveFileWithName name: String, URL: NSURL) {
        removeActiveTransfer(transfer)
        incomingFileTransferDelegate?.incomingFileTransfer(transfer, didReceiveFileWithName: name, URL: URL)
    }
    
    public func incomingFileTransfer(transfer: IncomingFileTransfer, didFailToReceiveFileWithName name: String, error: NSError) {
        removeActiveTransfer(transfer)
        incomingFileTransferDelegate?.incomingFileTransfer(transfer, didFailToReceiveFileWithName: name, error: error)
    }
    
    public func incomingFileTransfer(transfer: IncomingFileTransfer, didStartReceivingFileWithName name: String, progress: NSProgress) {
        incomingFileTransferDelegate?.incomingFileTransfer(transfer, didStartReceivingFileWithName: name, progress: progress)
    }
    
    // MARK: OutgoingFileTransferDelegate
    
    public func outgoingFileTransferDidComplete(transfer: OutgoingFileTransfer) {
        removeActiveTransfer(transfer)
        outgoingFileTransferDelegate?.outgoingFileTransferDidComplete(transfer)
    }
    
    public func outgoingFileTransfer(transfer: OutgoingFileTransfer, didFailWithError error: NSError) {
        removeActiveTransfer(transfer)
        outgoingFileTransferDelegate?.outgoingFileTransfer(transfer, didFailWithError: error)
    }
    
    public func outgoingFileTransfer(transfer: OutgoingFileTransfer, didStartWithProgress progress: NSProgress) {
        outgoingFileTransferDelegate?.outgoingFileTransfer(transfer, didStartWithProgress: progress)
    }
}
