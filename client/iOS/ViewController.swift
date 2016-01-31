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
    
    private var connectionManager: ConnectionManager?
    private var queuedPushNotifications = [PushNotification]()
    
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
        if let token = credentialStorage.activeToken {
            completeSetupWithToken(token)
        } else {
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
    
    private func completeSetupWithToken(token: AccessToken) {
        let connectionManager = ConnectionManager(client: client, token: token)
        connectionManager.getDeviceList {
            connectionManager.startMonitoring()
            
            self.queuedPushNotifications.forEach(connectionManager.queueNotification)
            self.queuedPushNotifications.removeAll()
        }
        self.connectionManager = connectionManager
    }
    
    // MARK: Notification Handling
    
    func handlePushNotification(notification: PushNotification) {
        if let connectionManager = connectionManager {
            connectionManager.queueNotification(notification)
        } else {
            queuedPushNotifications.append(notification)
        }
    }
    
    // MARK: LoginViewControllerDelegae
    
    func loginViewController(controller: LoginViewController, authenticatedWithToken token: AccessToken) {
        credentialStorage.activeToken = token
        completeSetupWithToken(token)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
