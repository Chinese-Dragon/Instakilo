//
//  EmailPassSignupViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import TWMessageBarManager
import SVProgressHUD
import FirebaseMessaging

class EmailPassSignupViewController: UIViewController {
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var ConfirmPasswordTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    @IBOutlet weak var FullNameTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    private var inputEmail: String?
    private var inputFullname: String?
    private var inputPassword: String?
    
    private lazy var dbRef = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    deinit {
        print("EmailPassSignUp removed")
    }
    
    private func setupUI() {
        print("setupUI")
        signupButton.layer.cornerRadius = 5
        signupButton.clipsToBounds = true
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }

    @IBAction func backToRoot(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func validateInputs() -> Bool {
        // validate
        guard let email = EmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !email.isEmpty else {
                // TODO: Show Error Message
                TWMessageBarManager().showMessage(withTitle: "Error", description: "Email can not be empty", type: .error)
                return false
        }
        
        guard let fullname = FullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !fullname.isEmpty else {
                
                TWMessageBarManager().showMessage(withTitle: "Error", description: "Name can not be empty", type: .error)
                return false
        }
        
        guard let password = PasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let comfirmPassword = ConfirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty, !comfirmPassword.isEmpty else {
                
                TWMessageBarManager().showMessage(withTitle: "Error", description: "Password can not be empty", type: .error)
                return false
        }
        
        guard password == comfirmPassword else {
            TWMessageBarManager().showMessage(withTitle: "Error", description: "Passwords should be the same", type: .error)
            return false
        }
        
        inputEmail = email
        inputFullname = fullname
        inputPassword = password
        
        return true
    }
    
    @IBAction func registerUser(_ sender: UIButton) {
        // perform segue after registerUser in the db
        if validateInputs(), let userEmail = inputEmail, let userFullname = inputFullname, let userPassword = inputPassword {
            
            SVProgressHUD.show()
            // create user authentication info
            Auth.auth().createUser(withEmail: userEmail , password: userPassword ) { (user, error) in
                
                guard let unwrappedUser = user, error == nil else {
                    DispatchQueue.main.async {
                        TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                    }
                    return
                }
                
                print(unwrappedUser.uid)
                // save to FIRBase
                let userRef = self.dbRef.child("Users")
                userRef.child(unwrappedUser.uid).setValue(
                    ["Full Name": userFullname,
                     "Email Address": userEmail,
                     "Phone Number": unwrappedUser.phoneNumber ?? "",
                     "Profile Photo": unwrappedUser.photoURL?.path ?? "",
                     "Gender": "",
                     "Bio": "",
                     "Website": "",
                     "Username": "",
                     "Password": userPassword
                    ]
                )
                
                let publicUserRef = self.dbRef.child("Public Users")
                publicUserRef.child(unwrappedUser.uid).setValue(
                    ["Full Name": userFullname,
                     "Profile Photo": unwrappedUser.photoURL?.path ?? "",
                     "Username": "",
                    ]
                )
          
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    // Successfully registed, navigate to homeVC
                    if let _ = Auth.auth().currentUser {
                        self.performSegue(withIdentifier: "SignupToApp", sender: nil)
						Messaging.messaging().subscribe(toTopic: unwrappedUser.uid)
                    }
                }
            }
        }
    }
}

extension EmailPassSignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case EmailTextField:
            FullNameTextField.becomeFirstResponder()
        case FullNameTextField:
            PasswordTextField.becomeFirstResponder()
        case PasswordTextField:
            ConfirmPasswordTextField.becomeFirstResponder()
        case ConfirmPasswordTextField:
            ConfirmPasswordTextField.resignFirstResponder()
        default:
            break
        }
        
        return true
    }
}
