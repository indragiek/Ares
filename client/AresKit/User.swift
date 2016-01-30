//
//  User.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct User: JSONDeserializable {
    public let username: String
    public let password: String
    
    // MARK: JSONDeserializable
    
    public init?(JSON: JSONDictionary) {
        if let username = JSON["username"] as? String,
               password = JSON["password"] as? String {
            self.username = username
            self.password = password
        } else {
            self.username = ""
            self.password = ""
            return nil
        }
    }
}
