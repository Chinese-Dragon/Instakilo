//
//  AddPostViewController.swift
//  Instakilo
//
//  Created by Mark on 1/9/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import TWMessageBarManager
import FirebaseStorage
import SVProgressHUD
import UITextView_Placeholder

protocol AddPostViewControllerDelegate {
    func didPostFeed()
}

class AddPostViewController: UIViewController {
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var postImage: UIImageView!
    
    var delegate:AddPostViewControllerDelegate?
    
    private lazy var postRef = Database.database().reference().child("Posts")
    private lazy var storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @IBAction func post(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        
        if validateInput() {
            // we can post the current post to Posts table
            uploadPost()
        }
    }
    
    @IBAction func goBack(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectImage(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
}

// MARK: -Helper Methods
private extension AddPostViewController {
    private func setupUI() {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
        postDescription.layer.cornerRadius = 5
        postDescription.clipsToBounds = true
        postDescription.layer.borderWidth = 0.5
        postDescription.layer.borderColor = UIColor.gray.cgColor
        
        postDescription.placeholder = "How are you?"
        postDescription.placeholderColor = UIColor.lightGray
    }
    
    private func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    private func uploadPost() {
        let postKey = postRef.childByAutoId().key
        let description = postDescription.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let userId = Auth.auth().currentUser!.uid
        
        let commentKey = postRef.childByAutoId().key
        let comment = ["Commenter": userId,
                       "Comment": description]
        
        let post = ["Description": description,
                    "Likes": 0,
                    "User ID": userId,
                    "Timestamp": [".sv": "timestamp"],
                    "Image Url": "",
                    "Comments": [commentKey: comment]
        ] as [String : Any]
        
        SVProgressHUD.show()
        postRef.child(postKey).setValue(post) { (error, ref) in
            guard error == nil else {
                SVProgressHUD.dismiss()
                TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                return
            }
            
            // successully post it all the info, need to upload image too
            self.uploadPostImage(with: postKey)
        }
    }
    
    private func validateInput() -> Bool {
        if postImage.image != nil, !postDescription.text.isEmpty {
            return true
        } else {
            // Show Message
            TWMessageBarManager().showMessage(withTitle: "Error", description: "Input need not to be empty", type: .error)
            return false
        }
    }
    
    private func uploadPostImage(with postID: String) {
        if let img = postImage.image {
            let imgData = UIImageJPEGRepresentation(img, 0.8)
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            let imageName = "PostImages/\(postID).jpeg"  // it's going to create the folder PostImages if not exist
            
            storageRef.child(imageName).putData(imgData!, metadata: metaData) { (metadata, error) in
                guard error == nil, let metaD = metadata else {
                    // TODO: Show Error Message
                    SVProgressHUD.dismiss()
                    TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                    return
                }
                let imageUrl = metaD.downloadURL()?.absoluteString ?? ""
                
                // success then update post image url with firebase sotrage url
                self.postRef.child(postID).updateChildValues(["Image Url": imageUrl]) { (error, ref) in
                    
                    guard error == nil else {
                        TWMessageBarManager().showMessage(withTitle: "Error", description: error!.localizedDescription, type: .error)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        // successully upload post with all the info, call delegate
                        self.delegate?.didPostFeed()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}


extension AddPostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        postImage.image = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        print("cancel")
    }
}


