//
//  CreatedUser.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct CreatedUser: CustomStringConvertible, JSONDeserializable {
    public let username: String
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return "CreatedUser{username=\(username)}"
    }
    
    // MARK: JSONDeserializable
    
    public init?(JSON: JSONDictionary) {
        if let username = JSON["username"] as? String {
            self.username = username
        } else {
            self.username = ""
            return nil
        }
    }
}
