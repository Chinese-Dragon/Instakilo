//
//  AppDelegate.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import TWMessageBarManager
import Crashlytics
import UserNotifications

let appKey = "5a5d1297a3fc2768248b4727"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
	private lazy var center = UNUserNotificationCenter.current()
	
    private lazy var userRef = Database.database().reference().child("Users")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        Fabric.with([Crashlytics.self])
        
        let authStoryboard = UIStoryboard(name: "Authentication", bundle: Bundle.main)
		let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let _ = Auth.auth().currentUser {
            window?.rootViewController = mainStoryBoard.instantiateViewController(withIdentifier: "AppTabBarController")
        } else {
            window?.rootViewController = authStoryboard.instantiateViewController(withIdentifier: "MainNavigationController")
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		
        pushNotificationSetting()
		
        return true
    }
	
	private func pushNotificationSetting() {
		// Push Notification Settings
		center.delegate = self
		center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
			DispatchQueue.main.async {
				UIApplication.shared.registerForRemoteNotifications()
			}
		}
	}
	
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        FBSDKAppEvents.activateApp()
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }
}

// MARK: - Remote Notification
// ************************** For remote notification *************************
extension AppDelegate {
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let varAvgvalue = String(format: "%@", deviceToken as CVarArg)
		
		let token = varAvgvalue.trimmingCharacters(in: CharacterSet(charactersIn: "<>")).replacingOccurrences(of: " ", with: "")
		
		print(token)
		PushWizard.start(withToken: deviceToken, andAppKey: appKey, andValues: nil)
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error.localizedDescription)
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
		print(userInfo)
		PushWizard.handleNotification(userInfo, processOnlyStatisticalData: false)
	}
}


extension AppDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		
		// handle notification
	}
}
