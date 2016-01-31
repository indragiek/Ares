//
//  DevicesManager.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation

public protocol DevicesManagerDelegate: AnyObject {
    func devicesManager(manager: DevicesManager, didUpdateDevices devices: [Device])
}

public struct Device {
    public enum Availability {
        case None
        case Local
        case Remote
    }
    
    let registeredDevice: RegisteredDevice
    let availability: Availability
}

public final class DevicesManager {
    private let client: Client
    private let token: AccessToken
    
    private(set) public var devices = [Device]() {
        didSet {
            delegate?.devicesManager(self, didUpdateDevices: devices)
        }
    }
    
    weak var delegate: DevicesManagerDelegate?
    
    public init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
    }
    
    
}