//
//  Post.swift
//  Instakilo
//
//  Created by Mark on 1/9/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation
class Post {
    var postId: String
    var postDescription: String?
    var postImageUrl: URL?
    var postLikeCount: Int = 0
    var location: String?
    var postTime: Double
    var publicUser: PublicUser
    var isLiked: Bool = false
    // a list of commenterID
    
    init(postId: String, postDescription: String?, postImageUrl: URL?, postLikeCount: Int, location: String?, postTime: Double, publicUser: PublicUser, isLiked: Bool) {
        self.postId = postId
        self.postDescription = postDescription
        self.postImageUrl = postImageUrl
        self.postLikeCount = postLikeCount
        self.location = location
        self.postTime = postTime
        self.publicUser = publicUser
        self.isLiked = isLiked
    }
}
