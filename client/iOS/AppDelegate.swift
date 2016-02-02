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
    private var viewController: ViewController!
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let settings = UIUserNotificationSettings(forTypes: [.Alert], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = .whiteColor()
        
        apnsManager = APNSManager()
        let client = Client()
        let credentialStorage = CredentialStorage.sharedInstance
        viewController = ViewController(client: client, credentialStorage: credentialStorage, apnsManager: apnsManager)
        
        window?.rootViewController = UINavigationController(rootViewController: viewController)
        window?.makeKeyAndVisible()
        
        if let payload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject],
            notification = PushNotification(payload: payload) {
            viewController.handlePushNotification(notification)
        }
        
        return true
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        apnsManager.token = deviceToken.hexadecimalString
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        guard let notification = PushNotification(payload: userInfo) else { return }
        viewController.handlePushNotification(notification)
    }
}
