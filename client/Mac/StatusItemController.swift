//
//  StatusItemController.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Cocoa
import AresKit

@objc final class StatusItemController: NSObject, DevicesManagerDelegate, NSWindowDelegate {
    let statusItem: NSStatusItem
    private let client: Client
    private let token: AccessToken
    private let devicesManager: DevicesManager
    
    init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
        
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        devicesManager = DevicesManager(client: client, token: token)
        
        super.init()
        
        devicesManager.delegate = self
        devicesManager.getDeviceList()
        
        if let button = statusItem.button {
            button.title = "🚀"
            if let window = button.window {
                window.registerForDraggedTypes([NSFilenamesPboardType])
                window.delegate = self
            }
        }
    }
    
    // MARK: DevicesManagerDelegate
    
    func devicesManager(manager: DevicesManager, didUpdateDevices devices: [Device]) {
        let menu = NSMenu(title: "Devices")
        for device in devices {
            let registeredDevice = device.registeredDevice
            if registeredDevice.uuid == client.deviceUUID {
                continue
            }
            menu.addItemWithTitle(registeredDevice.deviceName, action: nil, keyEquivalent: "")
        }
        statusItem.menu = menu
    }
    
    func devicesManager(manager: DevicesManager, didFailWithError error: NSError) {
        print(error)
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
                   device = devicesManager.devices.first?.registeredDevice {
                for file in files {
                    client.send(token, filePath: file, device: device) { result in
                        if let error = result.error {
                            print(error)
                        }
                    }
                }
                print(files)
                return true
            }
        }
        return false
    }
}
