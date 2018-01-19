//
//  UserTableViewCell.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage

protocol UserTableViewCellDelegate {
	func addFriendTapped(_ cell: UserTableViewCell)
}

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var friendButton: UIButton!
	
	var delegate: UserTableViewCellDelegate?
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        usernameLabel.clipsToBounds = true
        userImageView.layer.masksToBounds = true
        backgroundColor = UIColor.background
    }
	
	@IBAction func addFriend(_ sender: UIButton) {
		delegate?.addFriendTapped(self)
	}
	
	func configure(with user: PublicUser) {
		self.userImageView?.sd_setImage(with: user.photoUrl, completed: nil)
		self.usernameLabel.text = user.username
		self.fullnameLabel.text = user.fullname
		self.friendButton.isSelected = CurrentUser.sharedInstance.following.contains(user.id)
	}
}
