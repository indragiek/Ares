//
//  PushNotification.swift
//  Ares
//
//  Created by Indragie on 1/31/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct PushNotification: CustomStringConvertible {
    public let deviceUUID: String
    public let filePath: String
    
    public init?(payload: [NSObject: AnyObject]) {
        if let deviceUUID = payload["device_id"] as? String,
               filePath = payload["path"] as? String {
            self.deviceUUID = deviceUUID
            self.filePath = filePath
        } else {
            self.deviceUUID = ""
            self.filePath = ""
            return nil
        }
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return "PushNotification{deviceUUID=\(deviceUUID), filePath=\(filePath)}"
    }
}
