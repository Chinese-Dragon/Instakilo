//
//  ViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SVProgressHUD
import FirebaseAuth
import FirebaseDatabase
import TWMessageBarManager
import FirebaseMessaging

class LoginViewController: UIViewController {
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var instaHeaderTextVie: UIImageView!
    
    var inputEmail: String?
    var inputPasssWord: String?
    
    private lazy var refUser = Database.database().reference().child("Users")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    deinit {
        print("LoginVC removed")
    }
    
    private func setupUI() {
        instaHeaderTextVie.image = instaHeaderTextVie.image!.withRenderingMode(.alwaysTemplate)
        instaHeaderTextVie.tintColor = UIColor.white
        loginButton.layer.cornerRadius = 5
        loginButton.clipsToBounds = true
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    private func validateInputs() -> Bool {
        // validate
        guard let email = EmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !email.isEmpty else {
                // TODO: Show Error Message
                TWMessageBarManager().showMessage(withTitle: "Error", description: "Email can not be empty", type: .error)
                return false
        }
        
        guard let password = PasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
             !password.isEmpty else {
                
                TWMessageBarManager().showMessage(withTitle: "Error", description: "Password can not be empty", type: .error)
                return false
        }
        
        inputEmail = email
        inputPasssWord = password
        
        return true
    }
    
    private func cleanUp() {
        EmailTextField.text = ""
        PasswordTextField.text = ""
    }
    
    @IBAction func login(_ sender: UIButton) {
        
        if validateInputs(), let email = inputEmail, let password = inputPasssWord {
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                guard error == nil, let user = user else {
                    // TODO : SHow message
                    TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                    return
                }
                
                // Successfully sined in
                DispatchQueue.main.async {
                    self.cleanUp()
                    self.performSegue(withIdentifier: "SigninToApp", sender: nil)
					Messaging.messaging().subscribe(toTopic: user.uid)
                }
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case EmailTextField:
            PasswordTextField.becomeFirstResponder()
        case PasswordTextField:
            PasswordTextField.resignFirstResponder()
        default:
            break
        }
        
        return true
    }
}

