//
//  UserSettingsTableViewController.swift
//  Instakilo
//
//  Created by Mark on 1/7/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit

class UserSettingsTableViewController: UITableViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var websiteTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    
    var currentUser: CurrentUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		setupUI()
		
        if let user = currentUser {
            updateFields(user)
        }
    }
	
	private func setupUI() {
		tableView.backgroundColor = UIColor.background
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40
	}
	
    private func updateFields(_ user: CurrentUser) {
        usernameTextField.text = user.username
        nameTextField.text = user.fullname
        bioTextField.text = user.bio
        websiteTextField.text = user.website
        phoneTextField.text = user.phoneNumber
        genderTextField.text = user.gender
        emailLabel.text = user.email
    }
}

extension UserSettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            websiteTextField.becomeFirstResponder()
        case websiteTextField:
            bioTextField.becomeFirstResponder()
        case bioTextField:
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            genderTextField.becomeFirstResponder()
        case genderTextField:
            genderTextField.resignFirstResponder()
        default:
            break
        }
        
        return true
    }
}
