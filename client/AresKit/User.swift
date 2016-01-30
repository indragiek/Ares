//
//  User.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

public struct User: CustomStringConvertible {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return "User{username=\(username), password=\(password)}"
    }
}
