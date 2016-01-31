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
import QuickLook

class ViewController: UIViewController, LoginViewControllerDelegate, ConnectionManagerDelegate, IncomingFileTransferDelegate, QLPreviewControllerDelegate {
    private enum State {
        case Default
        case WaitingForDiscovery
        case Transferring
    }
    
    private let credentialStorage: CredentialStorage
    private let apnsManager: APNSManager
    private let client: Client
    private var _KVOController: FBKVOController!
    
    private var connectionManager: ConnectionManager?
    private var queuedPushNotifications = [PushNotification]()
    private var temporaryFileURL: NSURL?
    
    private var state = State.Default {
        didSet {
            switch state {
            case .Default:
                placeholderImageView.hidden = false
                determinateProgressStackView.hidden = true
                indeterminateProgressStackView.hidden = true
                activityIndicator.stopAnimating()
            case .WaitingForDiscovery:
                placeholderImageView.hidden = true
                determinateProgressStackView.hidden = true
                indeterminateProgressStackView.hidden = false
                activityIndicator.startAnimating()
            case .Transferring:
                placeholderImageView.hidden = true
                determinateProgressStackView.hidden = false
                indeterminateProgressStackView.hidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var determinateProgressStackView: UIStackView!
    @IBOutlet weak var indeterminateProgressStackView: UIStackView!
    @IBOutlet weak var placeholderImageView: UIImageView!
    
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
        state = .WaitingForDiscovery
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
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressLabel.text = "Receiving \(fileName)..."
            self.state = .Transferring
        }
        
        _KVOController.observe(progress, keyPath: "fractionCompleted", options: []) { (_, _, _) in
            dispatch_async(dispatch_get_main_queue()) {
                self.progressView.progress = Float(progress.fractionCompleted)
            }
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
        temporaryFileURL = fixedURL
        
        let fm = NSFileManager.defaultManager()
        do { try fm.removeItemAtURL(fixedURL) } catch _ {}
        do {
            try fm.moveItemAtURL(URL, toURL: fixedURL)
        } catch let error {
            fatalError("Error moving \(URL) to \(fixedURL): \(error)")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            let previewController = PreviewViewController(fileName: name, URL: fixedURL)
            previewController.delegate = self
            self.presentViewController(previewController, animated: true) {
                self.state = .Default
            }
        }
    }
    
    // MARK: QLPreviewControllerDelegate
    
    func previewControllerDidDismiss(controller: QLPreviewController) {
        guard let fileURL = temporaryFileURL else { return }
        do {
            try NSFileManager.defaultManager().removeItemAtURL(fileURL)
        } catch _ {}
    }
}
