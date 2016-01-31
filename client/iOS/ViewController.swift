//
//  ViewController.swift
//  Ares-iOS
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import UIKit
import AresKit

class ViewController: UIViewController, LoginViewControllerDelegate {
    private var credentialStorage: CredentialStorage!
    private var client: Client!

    override func viewDidLoad() {
        super.viewDidLoad()
        credentialStorage = CredentialStorage.sharedInstance
        client = Client(URL: NSURL(string: "http://localhost:5000")!)
        
        if credentialStorage.activeToken == nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.presentLoginViewController()
            }
        }
    }
    
    // MARK: Login
    
    private func presentLoginViewController() {
        let loginViewController = LoginViewController()
        loginViewController.client = client
        loginViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: loginViewController)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: LoginViewControllerDelegae
    
    func loginViewController(controller: LoginViewController, authenticatedWithToken token: AccessToken) {
        credentialStorage.activeToken = token
        dismissViewControllerAnimated(true, completion: nil)
    }
}
