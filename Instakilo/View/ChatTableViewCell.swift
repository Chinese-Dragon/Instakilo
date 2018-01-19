//
//  ChatTableViewCell.swift
//  Instakilo
//
//  Created by Mark on 1/17/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage

class ChatTableViewCell: UITableViewCell {
	@IBOutlet weak var receiverImage: UIImageView!
	@IBOutlet weak var receiverUsername: UILabel!
	@IBOutlet weak var lastConversionText: UILabel!
	@IBOutlet weak var lastMsgTime: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		receiverImage.layer.cornerRadius = receiverImage.frame.size.width / 2
		receiverImage.clipsToBounds = true
		receiverImage.layer.masksToBounds = true
		backgroundColor = UIColor.background
    }
	
	func configure(with conversation: Conversation) {
		receiverImage.sd_setImage(with: conversation.receriver.photoUrl, completed: nil)
		receiverUsername.text = conversation.receriver.username
		lastConversionText.text = conversation.lastMessage
		lastMsgTime.text = conversation.lastMessageTime.readableTime
	}
}
