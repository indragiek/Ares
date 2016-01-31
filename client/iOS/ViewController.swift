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
    private let credentialStorage: CredentialStorage
    private let apnsManager: APNSManager
    private let client: Client
    
    init(client: Client, credentialStorage: CredentialStorage, apnsManager: APNSManager) {
        self.client = client
        self.credentialStorage = credentialStorage
        self.apnsManager = apnsManager
        
        super.init(nibName: nil, bundle: nil)
        
        title = "🚀 Ares"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if credentialStorage.activeToken == nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.presentLoginViewController()
            }
        }
    }
    
    // MARK: Login
    
    private func presentLoginViewController() {
        let loginViewController = LoginViewController(apnsManager: apnsManager)
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
