//
//  UserSettingsViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import FirebaseMessaging

class UserSettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Options"
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    deinit {
        print("UserSettingsVC removed")
    }

    @IBAction func logOut(_ sender: UIButton) {
        
        // signout all the providers
        if let providerInfo = Auth.auth().currentUser?.providerData {
            for userInfo in providerInfo {
                print(userInfo.providerID)
                switch userInfo.providerID {
                case FacebookAuthProviderID:
                    FBSDKLoginManager().logOut()
                case GoogleAuthProviderID:
                    GIDSignIn.sharedInstance().signOut()
                default:
                    break
                }
            }
        }
        
        // sign out firebase auth
        do {
            try Auth.auth().signOut()
        } catch let error {
            print(error.localizedDescription)
        }
		
        destroyToLogin()
    }
    
    private func destroyToLogin() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        guard let rootViewController = window.rootViewController else {
            return
        }
		
		// unsubscribe user from push notification
		Messaging.messaging().unsubscribe(fromTopic: CurrentUser.sharedInstance.userId)
		
		// Reset Current User
		CurrentUser.sharedInstance.dispose()
		
		let authStoryboard = UIStoryboard(name: "Authentication", bundle: Bundle.main)
        let vc = authStoryboard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
		
        vc.view.frame = rootViewController.view.frame
        vc.view.layoutIfNeeded()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = vc
        }, completion: { completed in
            rootViewController.dismiss(animated: true, completion: nil)
        })
    }
}
