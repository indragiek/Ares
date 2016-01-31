//
//  StatusItemController.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Cocoa
import AresKit

@objc final class StatusItemController: NSObject, ConnectionManagerDelegate, OutgoingFileTransferDelegate, NSWindowDelegate {
    let statusItem: NSStatusItem
    private let client: Client
    private let token: AccessToken
    private let connectionManager: ConnectionManager
    
    init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
        
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        connectionManager = ConnectionManager(client: client, token: token)
        
        super.init()
        
        connectionManager.delegate = self
        connectionManager.outgoingFileTransferDelegate = self
        connectionManager.getDeviceList {
            self.connectionManager.startMonitoring()
        }
        
        if let button = statusItem.button {
            button.title = "🚀"
            if let window = button.window {
                window.registerForDraggedTypes([NSFilenamesPboardType])
                window.delegate = self
            }
        }
    }
    
    deinit {
        connectionManager.stopMonitoring()
    }
    
    // MARK: ConnectionManagerDelegate
    
    func connectionManager(manager: ConnectionManager, didUpdateDevices devices: [Device]) {
        let menu = NSMenu(title: "Devices")
        for device in devices {
            let registeredDevice = device.registeredDevice
            if registeredDevice.uuid == client.deviceUUID {
                continue
            }
            guard let item = menu.addItemWithTitle(registeredDevice.deviceName, action: "doNothing:", keyEquivalent: "") else { continue }
            item.target = self
            item.image = menuItemImageForDevice(device)
        }
        statusItem.menu = menu
    }
    
    @objc private func doNothing(sender: AnyObject) {}
    
    private func menuItemImageForDevice(device: Device) -> NSImage? {
        switch device.availability {
        case .Local:
            return NSImage(named: "green_orb")
        case .Remote:
            return NSImage(named: "yellow_orb")
        case .None:
            return NSImage(named: "red_orb")
        }
    }
    
    func connectionManager(manager: ConnectionManager, didFailWithError error: NSError) {
        print(error)
    }
    
    func connectionManager(manager: ConnectionManager, willBeginIncomingFileTransfer transfer: IncomingFileTransfer) {}
    
    func connectionManager(manager: ConnectionManager, willBeginOutgoingFileTransfer transfer: OutgoingFileTransfer) {
        print("Sending \(transfer.context.filePath)")
    }
    
    // MARK: OutgoingFileTransferDelegate
    
    func outgoingFileTransfer(transfer: OutgoingFileTransfer, didStartWithProgress progress: NSProgress) {
        print("Sending \(transfer.context.filePath) with \(progress)")
    }
    
    func outgoingFileTransfer(transfer: OutgoingFileTransfer, didFailWithError error: NSError) {
        print("Sending \(transfer.context.filePath) failed: \(error)")
    }
    
    func outgoingFileTransferDidComplete(transfer: OutgoingFileTransfer) {
        print("Sending \(transfer.context.filePath) succeeded")
    }
    
    // MARK: Drag and Drop
    
    func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return .Copy
    }
    
    func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard()
        guard let types = pasteboard.types else { return false }
        if types.contains(NSFilenamesPboardType) {
            if let files = pasteboard.propertyListForType(NSFilenamesPboardType) as? [String],
                   device = connectionManager.devices.first?.registeredDevice {
                for file in files {
                    client.send(token, filePath: file, device: device) { result in
                        if let error = result.error {
                            print(error)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
