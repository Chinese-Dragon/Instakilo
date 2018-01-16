//
//  PostTableViewCell.swift
//  Instakilo
//
//  Created by Mark on 1/9/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit

// Auto-Layout: Get UIImageView height to calculate cell height correctly
// https://stackoverflow.com/questions/26041820/auto-layout-get-uiimageview-height-to-calculate-cell-height-correctly

protocol PostTableViewCellDelegate {
    func likeTapped(_ cell: PostTableViewCell)
    func viewCommentsTapped(_ cell: PostTableViewCell)
    func shareTapped(_ cell: PostTableViewCell)
    func likeCountTapped(_ cell: PostTableViewCell)
}

class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userLocationLabel: UILabel!
    @IBOutlet weak var postTimeLabel: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var likeCountButton: UIButton!
    @IBOutlet weak var postCardView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var comments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    var delegate: PostTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userImage.layer.cornerRadius = userImage.frame.size.width / 2
        userImage.clipsToBounds = true
        userImage.layer.masksToBounds = true
        
        postCardView.layer.cornerRadius = 5
        postCardView.clipsToBounds = true
        postCardView.layer.masksToBounds = true
    }
    
    @IBAction func likeOrUnlike(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        delegate?.likeTapped(self)
    }
    
    @IBAction func viewComments(_ sender: UIButton) {
        delegate?.viewCommentsTapped(self)
    }
    
    @IBAction func sharePost(_ sender: UIButton) {
        delegate?.shareTapped(self)
    }
    
    @IBAction func showLikedUser(_ sender: UIButton) {
        delegate?.likeCountTapped(self)
    }
    
    func configure(post: Post) {
        let currentPostUser = post.publicUser
        
        self.likeCountButton.setTitle("\(post.postLikeCount) Likes", for: .normal)
        self.comments.setTitle(post.postDescription, for: .normal)
        self.userImage.sd_setImage(with: currentPostUser.photoUrl, completed: nil)
        self.userImage.sd_setIndicatorStyle(.gray)
        
        self.usernameLabel.text = currentPostUser.username
        self.userLocationLabel.text = post.location
        self.postTimeLabel.text = post.postTime.timeElapsed
        self.postImage.sd_setImage(with: post.postImageUrl)
        self.postImage.sd_setIndicatorStyle(.gray)
        self.likeButton.isSelected = post.isLiked
    }
}
