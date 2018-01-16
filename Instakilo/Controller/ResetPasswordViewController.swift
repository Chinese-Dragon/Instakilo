//
//  ResetPasswordViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import TWMessageBarManager

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var ResetEmailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    deinit {
        print("ResetPasswordVC removed")
    }
    
    @IBAction func sendResetLink(_ sender: UIButton) {
        if let email = ResetEmailTextField.text, !email.isEmpty {
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                DispatchQueue.main.async {
                    if error != nil {
                        TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                    } else {
                        TWMessageBarManager().showMessage(withTitle: "Success", description: "Reset password email sent", type: .success)
                    }
                }
            }
        } else {
             TWMessageBarManager().showMessage(withTitle: "Error", description: "Need a valid email address", type: .error)
        }
    }
    
    @IBAction func backToSignin(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}
