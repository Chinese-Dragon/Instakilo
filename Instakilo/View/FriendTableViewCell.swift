//
//  FriendTableViewCell.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var friendImageVIew: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        friendImageVIew.layer.cornerRadius = friendImageVIew.frame.size.width / 2
        friendImageVIew.clipsToBounds = true
        friendImageVIew.layer.masksToBounds = true
        backgroundColor = UIColor.background
    }
}
