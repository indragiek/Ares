//
//  RegisteredDevice.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct RegisteredDevice: CustomStringConvertible, JSONDeserializable {
    public let uuid: String
    public let deviceName: String
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return "RegisteredDevice{uuid=\(uuid), deviceName=\(deviceName)}"
    }
    
    // MARK: JSONDeserializable
    
    public init?(JSON: JSONDictionary) {
        if let uuid = JSON["uuid"] as? String,
               deviceName = JSON["device_name"] as? String {
            self.uuid = uuid
            self.deviceName = deviceName
        } else {
            self.uuid = ""
            self.deviceName = ""
            return nil
        }
    }
}
