//
//  EditProfileViewController.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import TWMessageBarManager
import SVProgressHUD

protocol EditProfileViewControllerDelegate {
    func didUpdate(_ user: CurrentUser)
}

class EditProfileViewController: UIViewController {

    @IBOutlet weak var profileImgae: UIImageView!
    
    var currentUser: CurrentUser?
    
    var containerVC: UserSettingsTableViewController?

    var delegate: EditProfileViewControllerDelegate?
    
    private lazy var storageRef = Storage.storage().reference()
    private lazy var dbRef = Database.database().reference()
    
    @IBAction func pickProfileImage(_ sender: UIButton) {
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        pickerVC.sourceType = .photoLibrary
        present(pickerVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if let user = currentUser {
            updateUserInfo(with: user)
        }
        setupUI()
    }
    
    deinit {
        print("EditProfileVC removed")
    }
    
    private func setupUI() {
        profileImgae.layer.cornerRadius = profileImgae.frame.size.width / 2
        profileImgae.clipsToBounds = true
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    private func updateUserInfo(with updatedUser: CurrentUser) {
        print("ready to set image")
        profileImgae.sd_setImage(with: updatedUser.profileImageUrl, completed: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mEmbeddedSegue", let targetVC = segue.destination as? UserSettingsTableViewController {
            print("Set up container VC properties")
            containerVC = targetVC
            targetVC.currentUser = currentUser
        }
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveUserSettings(_ sender: UIBarButtonItem) {
        guard let containerSettingVC = containerVC else {
            return
        }
        
        currentUser?.fullname = containerSettingVC.nameTextField.text
        currentUser?.username = containerSettingVC.usernameTextField.text
        currentUser?.bio = containerSettingVC.bioTextField.text
        currentUser?.gender = containerSettingVC.genderTextField.text
        currentUser?.website = containerSettingVC.websiteTextField.text
        currentUser?.phoneNumber = containerSettingVC.phoneTextField.text
        
        uploadProfileImage(with: currentUser)
    }
    
    private func updateToDB(with updatedUser: CurrentUser?) {
        guard let userToBeSaved = updatedUser else {
            SVProgressHUD.dismiss()
            return
        }
        
        let updatedInfo = ["Full Name": userToBeSaved.fullname ?? "",
                           "Phone Number": userToBeSaved.phoneNumber ?? "",
                           "Profile Photo": userToBeSaved.profileImageUrl?.absoluteString ?? "",
                           "Gender": userToBeSaved.gender ?? "Not Specified",
                           "Bio": userToBeSaved.bio ?? "",
                           "Website": userToBeSaved.website ?? "",
                           "Username": userToBeSaved.username ?? ""]
        
        let updatedPublicUserInfo = ["Full Name": userToBeSaved.fullname ?? "",
                                     "Profile Photo": userToBeSaved.profileImageUrl?.absoluteString ?? "",
                                     "Username": userToBeSaved.username ?? ""]
        
        let userRef = dbRef.child("Users")
        let publicUserRef = dbRef.child("Public Users")
            
        userRef.child(userToBeSaved.userId).updateChildValues(updatedInfo) { (error, ref) in
            guard error == nil else {
                SVProgressHUD.dismiss()
                // TODO: Show error
                return
            }
            
            publicUserRef.child(userToBeSaved.userId).updateChildValues(updatedPublicUserInfo) { (error, ref) in
                guard error == nil else {
                    SVProgressHUD.dismiss()
                    return
                }
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    TWMessageBarManager().showMessage(withTitle: "Succes", description: "Successfully Updated Info", type: .success)
                    self.delegate?.didUpdate(userToBeSaved)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        print("About to save to DB")
    }
    
    
    private func uploadProfileImage(with user: CurrentUser?) {
        guard let userToBeSaved = user else {
            return
        }
        
        if let img = profileImgae.image {
            let imgData = UIImageJPEGRepresentation(img, 0.8)
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            let imageName = "UserImages/\(userToBeSaved.userId).jpeg"  // it's going to create the folder Userimages if not exist
            
            SVProgressHUD.show()
            storageRef.child(imageName).putData(imgData!, metadata: metaData) { (metadata, error) in
                guard error == nil else {
                    // TODO: Show Error Message
                    SVProgressHUD.dismiss()
                    return
                }
                
                // TODO: Show Success Message
                // update current user's imageurl
                self.currentUser?.profileImageUrl = URL(string: (metadata?.downloadURL()?.absoluteString)!)
                
                self.updateToDB(with: self.currentUser)
            }
        }
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profileImgae.image = image
    }
}
