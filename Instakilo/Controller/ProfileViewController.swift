//
//  ProfileViewController.swift
//  Instakilo
//
//  Created by Mark on 1/16/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage
import SVProgressHUD

class ProfileViewController: UIViewController {
	@IBOutlet weak var BioLabel: UILabel!
	@IBOutlet weak var fullnameLabel: UILabel!
	@IBOutlet weak var postLabel: UILabel!
	@IBOutlet weak var followersLabelL: UILabel!
	@IBOutlet weak var profileImage: UIImageView!
	@IBOutlet weak var followingLabel: UILabel!
	@IBOutlet weak var profileCard: UIView!
	@IBOutlet weak var editProfileButton: UIButton!
	@IBOutlet weak var settingOptionButton: UIButton!
	
	private var currentUser: CurrentUser? {
		didSet {
			if view.window != nil {
				// update UI with currentUser Data
				updateUIWith(user: currentUser!)
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		fetchCurrentUser()
    }
	
	private func setupUI() {
		profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
		profileImage.clipsToBounds = true
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
		profileCard.backgroundColor = UIColor.background
	}
	
	private func fetchCurrentUser() {
		SVProgressHUD.show()
		FIRAppService.shareInstance.fetchCurrentUserData { (user, error) in
			SVProgressHUD.dismiss()
			DispatchQueue.main.async {
				self.currentUser = user
			}
		}
	}
	
	private func showIndicators() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}
	
	private func hideIndicators() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = false
	}
	
	private func updateUIWith(user: CurrentUser) {
		BioLabel.text = user.bio
		fullnameLabel.text = user.fullname
		postLabel.text = user.posts.count.description
		followersLabelL.text = user.follwers.count.description
		followingLabel.text = user.following.count.description
		profileImage.sd_setImage(with: user.profileImageUrl, completed: nil)
		
		navigationItem.title = user.username
		
		editProfileButton.layer.borderWidth = 0.5
		editProfileButton.layer.borderColor = UIColor.gray.cgColor
		editProfileButton.layer.cornerRadius = 5
		
		settingOptionButton.layer.borderWidth = 0.5
		settingOptionButton.layer.borderColor = UIColor.gray.cgColor
		settingOptionButton.layer.cornerRadius = 5
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "EditProfileSegue", let targetVC = segue.destination.contents as? EditProfileViewController {
			targetVC.currentUser = currentUser
		}
	}
}
