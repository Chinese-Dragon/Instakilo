//
//  FirebaseService.swift
//  Instakilo
//
//  Created by Mark on 1/12/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


// how to handle nested network call:
// https://stackoverflow.com/questions/35906568/wait-until-swift-for-loop-with-asynchronous-network-requests-finishes-executing

class FIRAppService: NSObject {
    static let shareInstance = FIRAppService()
    private override init() {}
    
    typealias FetchFeedsResultHandler = ([Post]?, String?) -> ()
    typealias FetchPublicUserResultHandler = (PublicUser?, String?) -> ()
    typealias FirebaseDictionary = [String: Any]
    
    private lazy var dbRef = Database.database().reference()
    private lazy var postRef = Database.database().reference().child("Posts")
    private lazy var publicUserRef = Database.database().reference().child("Public Users")
    private lazy var userRef = Database.database().reference().child("Users")
    
    private func checkLiked(postObj: FirebaseDictionary) -> Bool{
        var hasLiked = false
        
        // check if there are any people who like the post
        if let likedByUsers = postObj["Liked By"] as? [String: String] {
            
            // check if the post is liked by current user
            for (_, likedUserId) in likedByUsers {
                if likedUserId == Auth.auth().currentUser!.uid {
                    hasLiked = true
                }
            }
        }
        
        return hasLiked
    }
    
    func fetchFeeds(completion: @escaping FetchFeedsResultHandler) {
        var errorMessage: String?
        var tempPosts = [Post]()
        
        let fetchFeedGroup = DispatchGroup()
        let fetchUserGroup = DispatchGroup()
        
        fetchFeedGroup.enter()
        postRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let postsDict = snapshot.value as? [String: Any] else {
                errorMessage = "No post found"
                completion(nil, errorMessage)
                return
            }
            
            for (postID, postObj) in postsDict {
                if let obj = postObj as? [String: Any],
                    let description = obj["Description"] as? String,
                    let imageUrlStr = obj["Image Url"] as? String,
                    let postImageURL = URL(string: imageUrlStr),
                    let timestamp = obj["Timestamp"] as? Double,
                    let likeCount = obj["Likes"] as? Int,
                    let publicUserId = obj["User ID"] as? String {
                    
                    let hasLiked = self.checkLiked(postObj: obj)
                    
                    fetchUserGroup.enter()
                    self.fetchPublicUser(with: publicUserId) { (pubUser, error) in
                        fetchUserGroup.leave()
                        
                        guard let user = pubUser, error == nil else {
                            errorMessage = (errorMessage ?? "") + error!
                            completion(nil, errorMessage)
                            return
                        }
                        
                        let post = Post(postId: postID, postDescription: description, postImageUrl: postImageURL, postLikeCount: likeCount, location: nil, postTime: timestamp, publicUser: user, isLiked: hasLiked)
                        
                        tempPosts.append(post)
                    }
                } else {
                    errorMessage = (errorMessage ?? "") + "something went wrong when parsing post \n"
                }
            }
            
            fetchUserGroup.notify(queue: .main) {
                fetchFeedGroup.leave()
            }
        }
        
        fetchFeedGroup.notify(queue: .main) {
            print(tempPosts.count)
            completion(tempPosts, errorMessage)
        }
    }
    
    func fetchPublicUser(with userID: String,
                         completion: @escaping FetchPublicUserResultHandler) {
        var errorMessage: String?
        
        publicUserRef.child(userID).observeSingleEvent(of: .value) { (snap) in
            // Get public user info dictionary
            if let pubUsersDict = snap.value as? [String: Any] {
                let fullname = pubUsersDict["Full Name"] as! String
                let username = pubUsersDict["Username"] as! String
                let photoUrlStr = pubUsersDict["Profile Photo"] as! String
                
                // construct the public user
                let pubUser = PublicUser(fullname: fullname, id: userID, username: username, photoUrl: URL(string: photoUrlStr), following: nil, followers: nil)
                
                completion(pubUser, errorMessage)
            } else {
                errorMessage = "Error When Parsing Public User Data \n"
                completion(nil, errorMessage)
            }
        }
    }
    
    func likeOrUnlikePost(with postID: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let currentPostRef = postRef.child(postID)
        var hasLiked = false
        
        // check if current user is in Liked list
        currentPostRef.child("Liked By").observeSingleEvent(of: .value) { (snapshot) in
            if let likedUserDict = snapshot.value as? [String: String] {
                for (key, likedUserId) in likedUserDict {
                    if likedUserId == currentUserId {
                        // we've already liked, unlike it
                        hasLiked = true
                        currentPostRef.child("Liked By/\(key)").removeValue()
                    }
                }
            }
            
            if !hasLiked {
                // we need to like it
                let key = currentPostRef.childByAutoId().key
                let like = [key: currentUserId]
                currentPostRef.child("Liked By").updateChildValues(like)
            }
            
            // finally update the current like count by counting number of likedBy users
            currentPostRef.child("Liked By").observeSingleEvent(of: .value) { (snapshot) in
                let count = ((snapshot.value as? [String: String])?.count) ?? 0
                let updateLike = ["Likes": count]
                
                currentPostRef.updateChildValues(updateLike)
            }
        }
    }
	
//	func fetchCurrentUserData() {
//		guard let id = Auth.auth().currentUser?.uid else { return }
//
//		let userRef = dbRef.child("Users")
//		userRef.child(id).observeSingleEvent(of: .value) { (snapshot) in
//			if let userObj = snapshot.value as? [String: Any],
//				let fullName = userObj["Full Name"] as? String,
//				let email = userObj["Email Address"] as? String,
//				let bio = userObj["Bio"] as? String,
//				let gender = userObj["Gender"] as? String,
//				let password = userObj["Password"] as? String,
//				let phoneNumber = userObj["Phone Number"] as? String,
//				let profilePhotoUrlStr = userObj["Profile Photo"] as? String,
//				let username = userObj["Username"] as? String,
//				let website = userObj["Website"] as? String {
//
//				// update current User
//				self.currentUser = CurrentUser(userId: id, email: email, fullname: fullName, password: password, profileImageUrl: URL(string: profilePhotoUrlStr), username: username, website: website, bio: bio, phoneNumber: phoneNumber, gender: gender)
//
//				DispatchQueue.main.async {
//
//				}
//			}
//		}
//	}
	
}
