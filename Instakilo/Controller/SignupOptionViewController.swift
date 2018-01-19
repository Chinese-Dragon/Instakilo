//
//  SignupViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase
import TWMessageBarManager
import SVProgressHUD
import FacebookLogin
import FBSDKLoginKit
import FirebaseMessaging

class SignupOptionViewController: UIViewController {
    
    private lazy var dbRef = Database.database().reference()

    @IBOutlet weak var instagramHeaderImage: UIImageView!
    @IBOutlet weak var FaceBookLoginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    deinit {
        print("SignupOptionVC removed")
    }
    
    @IBAction func googleSignin(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func backToRoot(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func setupUI() {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        FaceBookLoginButton.delegate = self
        FaceBookLoginButton.readPermissions = ["public_profile", "email"]
        instagramHeaderImage.image = instagramHeaderImage.image!.withRenderingMode(.alwaysTemplate)
        instagramHeaderImage.tintColor = UIColor.white
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    private func oAuthLoginWith(credential: AuthCredential) {
        
        Auth.auth().signIn(with: credential) { (user, error) in
            guard error == nil, let user = user else {
                SVProgressHUD.dismiss()
                
                // TODO: Show Message
                TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                
                // logout the current provider to reset the access token
                if credential.provider == FacebookAuthProviderID {
                    FBSDKLoginManager().logOut()
                } else {
                    GIDSignIn.sharedInstance().signOut()
                }
                return
            }
			
			
			// check if we already user records in our db
			let userRef = self.dbRef.child("Users")
			let publicUserRef = self.dbRef.child("Public Users")
			
			userRef.observeSingleEvent(of: .value) { (snapshot) in
				if !snapshot.hasChild(user.uid) {
					// setup inital user record if non exist
					userRef.child(user.uid).setValue(
						["Full Name": user.displayName ?? "",
						 "Email Address": user.email ?? "",
						 "Phone Number": user.phoneNumber ?? "",
						 "Profile Photo": user.photoURL?.absoluteString,
						 "Gender": "",
						 "Bio": "",
						 "Website": "",
						 "Username": "",
						 "Password": ""
						]
					)
					
					publicUserRef.child(user.uid).setValue(
						["Full Name": user.displayName ?? "",
						 "Profile Photo": user.photoURL?.absoluteString,
						 "Username": "",
						 ]
					)
				}
				
				// if already exist then just fetch currentInfo, and login
				DispatchQueue.main.async {
					SVProgressHUD.dismiss()
					
					// Successfully registed, navigate to homeVC
					if let _ = Auth.auth().currentUser {
						self.performSegue(withIdentifier: "OAuthToApp", sender: nil)
						Messaging.messaging().subscribe(toTopic: user.uid)
					}
				}
			}
        }
    }
}

extension SignupOptionViewController: GIDSignInUIDelegate, GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            // TODO: Show Error Message
            print(error.localizedDescription)
            return
        }
        
        guard let authentication = user.authentication else  {
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        SVProgressHUD.show(withStatus: "Logging in...")
        oAuthLoginWith(credential: credential)
    }
}

extension SignupOptionViewController: FBSDKLoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        guard error == nil else {
            // TODO: SHow Message
            print(error.localizedDescription)
            return
        }
        
        guard !result.isCancelled, result.grantedPermissions.contains("email") else {
            // TODO: SHow Message
            return
        }
        SVProgressHUD.show(withStatus: "Logging in...")
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        oAuthLoginWith(credential: credential)
    }
}
