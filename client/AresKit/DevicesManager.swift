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
    func devicesManager(manager: DevicesManager, didFailWithError error: NSError)
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

public final class DevicesManager {
    private let client: Client
    private let token: AccessToken
    
    private(set) public var devices = [Device]() {
        didSet {
            delegate?.devicesManager(self, didUpdateDevices: devices)
        }
    }
    
    public weak var delegate: DevicesManagerDelegate?
    
    public init(client: Client, token: AccessToken) {
        self.client = client
        self.token = token
    }
    
    public func getDeviceList() {
        client.getDevices(token) { result in
            switch result {
            case let .Success(registeredDevices):
                self.devices = registeredDevices
                    .filter {
                        return $0.uuid != self.client.deviceUUID
                    }.map {
                        Device(registeredDevice: $0, availability: .None)
                    }
            case let .Failure(error):
                self.delegate?.devicesManager(self, didFailWithError: error)
            }
        }
    }
}
