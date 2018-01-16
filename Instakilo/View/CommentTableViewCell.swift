//
//  CommentTableViewCell.swift
//  Instakilo
//
//  Created by Mark on 1/11/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    @IBOutlet weak var commentContent: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.masksToBounds = true
    }
}
