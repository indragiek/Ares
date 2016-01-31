//
//  AppDelegate.swift
//  Ares-iOS
//
//  Created by Indragie on 1/30/16.
//  Copyright © 2016 Indragie Karunaratne. All rights reserved.
//

import UIKit
import AresKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var apnsManager: APNSManager!
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let settings = UIUserNotificationSettings(forTypes: [.Alert], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = .whiteColor()
        
        apnsManager = APNSManager()
        let client = Client(URL: NSURL(string: "https://ares-server.herokuapp.com")!)
        let credentialStorage = CredentialStorage.sharedInstance
        let viewController = ViewController(client: client, credentialStorage: credentialStorage, apnsManager: apnsManager)
        
        window?.rootViewController = UINavigationController(rootViewController: viewController)
        window?.makeKeyAndVisible()
        
        return true
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        apnsManager.token = deviceToken.hexadecimalString
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error)
    }
}
