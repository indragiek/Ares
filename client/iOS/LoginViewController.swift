//
//  LoginViewController.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import UIKit
import AresKit

protocol LoginViewControllerDelegate: AnyObject {
    func loginViewController(controller: LoginViewController, authenticatedWithToken token: AccessToken)
}

class LoginViewController: UIViewController {
    var client: Client?
    weak var delegate: LoginViewControllerDelegate?
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Login", comment: "")
    }

    private func constructUser() -> User {
        return User(username: usernameField.text ?? "", password: passwordField.text ?? "")
    }
    
    @IBAction func login(sender: UIButton) {
        authenticate(constructUser())
    }
    
    @IBAction func register(sender: UIButton) {
        guard let client = client else { return }
        let user = constructUser()
        client.register(user) { result in
            switch result {
            case .Success:
                self.authenticate(user)
            case let .Failure(error):
                self.showAlertForError(error)
            }
        }
    }
    
    private func authenticate(user: User) {
        guard let client = client else { return }
        client.authenticate(user) { result in
            switch result {
            case let .Success(token):
                self.delegate?.loginViewController(self, authenticatedWithToken: token)
            case let .Failure(error):
                self.showAlertForError(error)
            }
        }
    }
    
    private func showAlertForError(error: NSError) {
        let alertController = UIAlertController.alertControllerWithError(error)
        presentViewController(alertController, animated: true, completion: nil)
    }
}
