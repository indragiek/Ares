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
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    private var loginWindowController: LoginWindowController!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        loginWindowController = LoginWindowController(windowNibName: "LoginWindowController")
        loginWindowController.showWindow(nil)
//        client = Client(URL: NSURL(string: "http://localhost:5000")!)
//        client.authenticate(User(username: "indragie", password: "pass")) {
//            switch $0 {
//            case let .Success(token):
//                print(token)
//            case let .Failure(error):
//                print(error)
//            }
//        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

