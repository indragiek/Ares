//
//  AccessToken.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct AccessToken: CustomStringConvertible, JSONDeserializable {
    public let username: String
    public let token: String
    
    internal init(username: String, token: String) {
        self.username = username
        self.token = token
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return "AccessToken{username=\(username), token=\(token)}"
    }
    
    // MARK: JSONDeserializable
    
    public init?(JSON: JSONDictionary) {
        if let username = JSON["username"] as? String,
               token = JSON["token"] as? String {
            self.username = username
            self.token = token
        } else {
            self.username = ""
            self.token = ""
            return nil
        }
    }
}
