//
//  ViewController.swift
//  Ares-iOS
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import UIKit
import AresKit
import KVOController

class ViewController: UIViewController, LoginViewControllerDelegate, ConnectionManagerDelegate, IncomingFileTransferDelegate {
    private let credentialStorage: CredentialStorage
    private let apnsManager: APNSManager
    private let client: Client
    private var _KVOController: FBKVOController!
    
    private var connectionManager: ConnectionManager?
    private var queuedPushNotifications = [PushNotification]()
    private var temporaryFileURL: NSURL?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    init(client: Client, credentialStorage: CredentialStorage, apnsManager: APNSManager) {
        self.client = client
        self.credentialStorage = credentialStorage
        self.apnsManager = apnsManager
        
        super.init(nibName: nil, bundle: nil)
        
        self._KVOController = FBKVOController(observer: self)
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
        connectionManager.delegate = self
        connectionManager.incomingFileTransferDelegate = self
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
    
    // MARK: ConnectionManagerDelegate
    
    func connectionManager(manager: ConnectionManager, willBeginOutgoingFileTransfer transfer: OutgoingFileTransfer) {}
    
    func connectionManager(manager: ConnectionManager, willBeginIncomingFileTransfer transfer: IncomingFileTransfer) {
        print("Receiving \(transfer.context.filePath)")
    }
    
    func connectionManager(manager: ConnectionManager, didFailWithError error: NSError) {
        print(error)
    }
    
    func connectionManager(manager: ConnectionManager, didUpdateDevices devices: [Device]) {}
    
    // MARK: IncomingFileTransferDelegate
    
    func incomingFileTransfer(transfer: IncomingFileTransfer, didStartReceivingFileWithName name: String, progress: NSProgress) {
        let fileName = (transfer.context.filePath as NSString).lastPathComponent
        
        _KVOController.observe(progress, keyPath: "fractionCompleted", options: []) { (_, _, _) in
            dispatch_async(dispatch_get_main_queue()) {
                self.progressView.progress = Float(progress.fractionCompleted)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressLabel.text = "Receiving \(fileName)..."
        }
    }
    
    func incomingFileTransfer(transfer: IncomingFileTransfer, didFailToReceiveFileWithName name: String, error: NSError) {
        print("Failed to receive \(name): \(error)")
    }
    
    func incomingFileTransfer(transfer: IncomingFileTransfer, didReceiveFileWithName name: String, URL: NSURL) {
        if let _ = presentedViewController {
            dismissViewControllerAnimated(true) {
                self.showPreviewControllerForFileName(name, URL: URL)
            }
        } else {
            showPreviewControllerForFileName(name, URL: URL)
        }
    }
    
    private func showPreviewControllerForFileName(name: String, URL: NSURL) {
        guard let directoryURL = URL.URLByDeletingLastPathComponent else { return }
        let fixedURL = directoryURL.URLByAppendingPathComponent(name)
        
        let fm = NSFileManager.defaultManager()
        do { try fm.removeItemAtURL(fixedURL) } catch _ {}
        do {
            try fm.moveItemAtURL(URL, toURL: fixedURL)
        } catch let error {
            fatalError("Error moving \(URL) to \(fixedURL): \(error)")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            let previewController = PreviewViewController(fileName: name, URL: fixedURL)
            self.presentViewController(previewController, animated: true, completion: nil)
        }
    }
}
