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
import FirebaseMessaging

//let appKey = "5a5d1297a3fc2768248b4727"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
	private lazy var center = UNUserNotificationCenter.current()
    private lazy var userRef = Database.database().reference().child("Users")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        Fabric.with([Crashlytics.self])
        
        pushNotificationSetting()
		
		findEnterPoint()
		
		// NOTE: check how did we start the app (handle tap notification when not running)
		if let userInfo = launchOptions?[.remoteNotification] as? [String: Any] {
			print(userInfo)
			navToChat(with: userInfo)
		}
		
        return true
    }
	
	private func findEnterPoint() {
		let authStoryboard = UIStoryboard(name: "Authentication", bundle: Bundle.main)
		let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
		if let _ = Auth.auth().currentUser {
			window?.rootViewController = mainStoryBoard.instantiateViewController(withIdentifier: "AppTabBarController")
		} else {
			window?.rootViewController = authStoryboard.instantiateViewController(withIdentifier: "MainNavigationController")
		}
	}
	
	private func pushNotificationSetting() {
		// Push Notification Settings
		center.delegate = self
		center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
			DispatchQueue.main.async {
				UIApplication.shared.registerForRemoteNotifications()
			}
		}
		Messaging.messaging().delegate = self
		
		// need to set to false when enter background for saving bandwidth
		Messaging.messaging().shouldEstablishDirectChannel = true
		
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


// ************************** For Push notification *************************
// MARK: - Remote Notification
extension AppDelegate: MessagingDelegate {
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let varAvgvalue = String(format: "%@", deviceToken as CVarArg)
		
		let token = varAvgvalue.trimmingCharacters(in: CharacterSet(charactersIn: "<>")).replacingOccurrences(of: " ", with: "")
		
		print(token)
		Messaging.messaging().apnsToken = deviceToken
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error.localizedDescription)
	}
	

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
		print(userInfo)
		
		completionHandler(.newData)
		
	}

	// Firebase
	func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
		let token = Messaging.messaging().fcmToken
		print("FCM token: \(token ?? "")")
	}
	
	
	// NOTE: handle notification when in foreground
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

		// show notification only when the notification is not coming from the person we are chatting right now
		guard let userInfo = notification.request.content.userInfo as? [String : Any],
			let senderId = userInfo["gcm.notification.sender"] as? String,
			let root = window?.rootViewController as? UITabBarController,
			let chatNav = root.viewControllers?[3] as? UINavigationController,
			let chatVC = chatNav.visibleViewController as? ChatViewController,
			chatVC.receiver.id == senderId else {
				
			completionHandler(
				[UNNotificationPresentationOptions.alert,
				 UNNotificationPresentationOptions.sound,
				 UNNotificationPresentationOptions.badge])
				
			return
		}
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		
		// NOTE: handle tap notification when in background
		// if we have notification means the user is alreayd logged in,
		// we just need to
		if let userInfo = response.notification.request.content.userInfo as? [String : Any] {
			navToChat(with: userInfo)
		}
		
		completionHandler()
	}
	
	func navToChat(with userInfo: [String: Any]) {
		// Getting user info
		print(userInfo)
		let chatStoryboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
		if let senderId = userInfo["gcm.notification.sender"] as? String,
			let targetVC = chatStoryboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController,
			let root = window?.rootViewController as? UITabBarController,
			let chatNav = root.viewControllers?[3] as? UINavigationController,
			let friendsVC = (root.viewControllers?[1] as? UINavigationController)?.contents as? FriendsViewController,
			!(chatNav.visibleViewController is ChatViewController) {
			
			var receiver: PublicUser!
			for friend in friendsVC.friends {
				if friend.id == senderId {
					receiver = friend
				}
			}
			
			if receiver == nil {
				receiver =  PublicUser(fullname: nil, id: senderId, username: nil, photoUrl: nil, following: nil, followers: nil)
			}
			
			targetVC.receiver = receiver
			chatNav.pushViewController(targetVC, animated: true)
			root.selectedIndex = 3
		}
	}
}
