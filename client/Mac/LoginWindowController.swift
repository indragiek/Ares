//
//  LoginWindowController.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Cocoa
import AresKit

protocol LoginWindowControllerDelegate: AnyObject {
    func loginWindowController(controller: LoginWindowController, failedToAuthenticateWithError error: NSError)
    func loginWindowController(controller: LoginWindowController, authenticatedWithToken token: AccessToken)
}

class LoginWindowController: NSWindowController {
    var client: Client?
    weak var delegate: LoginWindowControllerDelegate?
    
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    convenience init() {
        self.init(windowNibName: "LoginWindowController")
    }
    
    private func constructUser() -> User {
        return User(username: usernameField.stringValue, password: passwordField.stringValue)
    }
    
    @IBAction func login(sender: NSButton) {
        authenticate(constructUser())
    }
    
    @IBAction func register(sender: NSButton) {
        guard let client = client else { return }
        let user = constructUser()
        client.register(user) { result in
            switch result {
            case .Success:
                self.authenticate(user)
            case let .Failure(error):
                self.delegate?.loginWindowController(self, failedToAuthenticateWithError: error)
            }
        }
    }
    
    private func authenticate(user: User) {
        guard let client = client else { return }
        client.authenticate(user) { result in
            switch result {
            case let .Success(token):
                self.delegate?.loginWindowController(self, authenticatedWithToken: token)
            case let .Failure(error):
                self.delegate?.loginWindowController(self, failedToAuthenticateWithError: error)
            }
        }
    }
}
