//
//  AppDelegate.swift
//  Ares
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import Cocoa
import AresKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, LoginWindowControllerDelegate {

    @IBOutlet weak var window: NSWindow!
    private var credentialStorage: CredentialStorage!
    private var client: Client!
    private var loginWindowController: LoginWindowController!
    private var statusItemController: StatusItemController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        credentialStorage = CredentialStorage.sharedInstance
        client = Client()
        
        if let token = credentialStorage.activeToken {
            completeSetupWithToken(token)
        } else {
            showLoginWindowController()
        }
    }
    
    func showLoginWindowController() {
        loginWindowController = LoginWindowController(windowNibName: "LoginWindowController")
        loginWindowController.client = client
        loginWindowController.delegate = self
        loginWindowController.showWindow(nil)
    }
    
    func tearDownLoginWindowController() {
        loginWindowController.window?.orderOut(nil)
        loginWindowController = nil
    }
    
    func completeSetupWithToken(token: AccessToken) {
        statusItemController = StatusItemController(client: client, token: token)
    }

    // MARK: LoginWindowControllerDelegate
    
    func loginWindowController(controller: LoginWindowController, authenticatedWithToken token: AccessToken) {
        credentialStorage.activeToken = token
        tearDownLoginWindowController()
        completeSetupWithToken(token)
    }
    
    func loginWindowController(controller: LoginWindowController, failedToAuthenticateWithError error: NSError) {
        NSApp.presentError(error)
    }
}
