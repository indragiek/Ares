//
//  CredentialStorage.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Foundation

private let ServiceName = "com.indragie.ares"
private let UserDefaultsUsernameKey = "username"

public final class CredentialStorage {
    static let sharedInstance = CredentialStorage()
    private let keychain: Keychain
    
    private init() {
        keychain = Keychain(service: ServiceName)
    }
    
    private var _activeToken: AccessToken?
    var activeToken: AccessToken? {
        get {
            if let accessToken = _activeToken {
                return accessToken
            }
            let ud = NSUserDefaults.standardUserDefaults()
            if let username = ud.stringForKey(UserDefaultsUsernameKey),
                   token = keychain[username] {
                let accessToken = AccessToken(username: username, token: token)
                _activeToken = accessToken
                return accessToken
            } else {
                return nil
            }
        }
        set {
            let ud = NSUserDefaults.standardUserDefaults()
            if let accessToken = newValue {
                ud.setObject(accessToken.username, forKey: UserDefaultsUsernameKey)
                keychain[accessToken.username] = accessToken.token
                _activeToken = accessToken
            } else {
                ud.removeObjectForKey(UserDefaultsUsernameKey)
                if let previousToken = _activeToken {
                    do {
                        try keychain.remove(previousToken.username)
                    } catch let error {
                        assertionFailure("Error removing credentials from keychain: \(error)")
                    }
                }
                _activeToken = nil
            }
        }
    }
}
