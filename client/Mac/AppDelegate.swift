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

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        credentialStorage = CredentialStorage.sharedInstance
        client = Client(URL: NSURL(string: "https://ares-server.herokuapp.com")!)
        if credentialStorage.activeToken != nil {
            setupStatusBarItem()
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
    
    func setupStatusBarItem() {
        guard let accessToken = credentialStorage.activeToken else {
            fatalError("Cannot set up status bar item without access token")
        }
    }

    // MARK: LoginWindowControllerDelegate
    
    func loginWindowController(controller: LoginWindowController, authenticatedWithToken token: AccessToken) {
        credentialStorage.activeToken = token
        tearDownLoginWindowController()
        setupStatusBarItem()
    }
    
    func loginWindowController(controller: LoginWindowController, failedToAuthenticateWithError error: NSError) {
        NSApp.presentError(error)
    }
}
