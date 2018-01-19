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
	typealias FetchCurrentUserResultHandler = (CurrentUser, String?) -> ()
	typealias FetchConversationResulthandler = ([Conversation]?, String?) -> ()
	typealias FetchUsersResultHandler = ([PublicUser]?, String?) -> ()
    typealias FirebaseDictionary = [String: Any]
    
    private lazy var dbRef = Database.database().reference()
    private lazy var postRef = Database.database().reference().child("Posts")
    private lazy var publicUserRef = Database.database().reference().child("Public Users")
    private lazy var userRef = Database.database().reference().child("Users")
    private lazy var conversationRef = Database.database().reference().child("Conversations")
	private lazy var notificationRef = Database.database().reference().child("notificationRequests")
	
	
	private lazy var currentUser = CurrentUser.sharedInstance
	
	
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
	
	func fetchCurrentUserData(completion: FetchCurrentUserResultHandler?) {
		let fetchUserGroup = DispatchGroup()
		let fetchUserComponentsGroup = DispatchGroup()
		var errorMessage: String?
		
		guard let id = Auth.auth().currentUser?.uid else { return }
		
		fetchUserGroup.enter()
		userRef.child(id).observeSingleEvent(of: .value) { [weak self] (snapshot) in
			guard let strongSelf = self else { return }
			if let userObj = snapshot.value as? [String: Any],
				let fullName = userObj["Full Name"] as? String,
				let email = userObj["Email Address"] as? String,
				let bio = userObj["Bio"] as? String,
				let gender = userObj["Gender"] as? String,
				let password = userObj["Password"] as? String,
				let phoneNumber = userObj["Phone Number"] as? String,
				let profilePhotoUrlStr = userObj["Profile Photo"] as? String,
				let profileURL = URL(string: profilePhotoUrlStr),
				let username = userObj["Username"] as? String,
				let website = userObj["Website"] as? String {
				
				strongSelf.currentUser.userId = id
				strongSelf.currentUser.fullname = fullName
				strongSelf.currentUser.email = email
				strongSelf.currentUser.bio = bio
				strongSelf.currentUser.gender = gender
				strongSelf.currentUser.password = password
				strongSelf.currentUser.phoneNumber = phoneNumber
				strongSelf.currentUser.profileImageUrl = profileURL
				strongSelf.currentUser.username = username
				strongSelf.currentUser.website = website
				
				fetchUserComponentsGroup.enter()
				// need to fetch post info
				strongSelf.fetchPostFor(currentUser: strongSelf.currentUser) { (error) in
					errorMessage = (errorMessage ?? "") + (error ?? "")
					fetchUserComponentsGroup.leave()
				}
				
				// need to fetch following and follower info
				fetchUserComponentsGroup.enter()
				strongSelf.fetchFollowInfoFor(currentUser: strongSelf.currentUser) { (error) in
					errorMessage = (errorMessage ?? "") + (error ?? "")
					fetchUserComponentsGroup.leave()
				}
				
				// when other componets are fetched
				fetchUserComponentsGroup.notify(queue: .main) {
					fetchUserGroup.leave()
				}
			} else {
				errorMessage = "Error pasing user data"
				fetchUserGroup.leave()
			}
		}
		
		// when everything finished
		fetchUserGroup.notify(queue: .main) {
			// now the currentUser should be properly configured
			completion?(self.currentUser, errorMessage)
		}
	}
	
	func fetchFollowInfoFor(currentUser: CurrentUser, completion: @escaping (String?) -> ()) {
		var errorMessage: String?
		currentUser.follwers.removeAll()
		currentUser.following.removeAll()
		
		publicUserRef.child(currentUser.userId).observeSingleEvent(of: .value) { (snapshot) in
			if let publicUserDict = snapshot.value as? [String: Any] {
				if let followingDict = publicUserDict["Following"] as? [String: String] {
					for (_, followingUserId) in followingDict {
						currentUser.following.append(followingUserId)
					}
				} else {
					errorMessage = "No following users"
				}
				
				if let followerDict = publicUserDict["Followers"] as? [String: String] {
					for (_, followerId) in followerDict {
						currentUser.follwers.append(followerId)
					}
				} else {
					errorMessage = "No followers"
				}
			} else {
				errorMessage = "Error pasing public user data"
			}
			
			completion(errorMessage)
		}
	}
	
	func fetchPostFor(currentUser: CurrentUser, completion: @escaping (String?) -> ()) {
		var errorMessage: String?
		currentUser.posts.removeAll()
		
		postRef.observeSingleEvent(of: .value) { (snapshot) in
			if let posts = snapshot.value as? [String: Any] {
				for (postId, postDict) in posts {
					if let postDictUnwrapped = postDict as? [String: Any],
						postDictUnwrapped["User ID"] as! String == currentUser.userId {
						currentUser.posts.append(postId)
					}
				}
			} else {
				errorMessage = "Error pasing post data"
			}
			
			completion(errorMessage)
		}
	}
	
	func fetchConversation(completion: @escaping FetchConversationResulthandler) {
		var errorMessage: String?
		var tempConvs: [Conversation] = []
		let fetchConversationGroup = DispatchGroup()
		let fetchPublicUserGroup = DispatchGroup()
		
		fetchConversationGroup.enter()
		if let currentUserId = currentUser.userId {
			conversationRef.observeSingleEvent(of: .value) { (snapshot) in
				guard let conversations = snapshot.value as? FirebaseDictionary else {
					errorMessage = "No conversation found"
					completion(nil, errorMessage)
					return
				}
				
				for (convKey, msgTimes) in conversations {
					if convKey.contains(currentUserId),
						let msgTimeDicts = msgTimes as? [String: Any] {
						
						// TODO: Need to modify
						let msgTimes = msgTimeDicts.keys.map { return Int($0)! }
						let lastMsgTime = msgTimes.max()!.description
						let lastMsgDict = (msgTimeDicts[lastMsgTime] as! FirebaseDictionary)
						let lastMsg = lastMsgDict["Message"] as! String
						
						// get recevier's id
						let receiverId = convKey.hasPrefix(currentUserId) ?
						convKey.dropFirst(currentUserId.count) :
						convKey.dropLast(currentUserId.count)
						
						// fetch receiver info
						fetchPublicUserGroup.enter()
						self.fetchPublicUser(with: receiverId.description) { (user, error) in
							fetchPublicUserGroup.leave()
							
							guard error == nil, let receiver = user else {
								errorMessage = (errorMessage ?? "") + error!
								return
							}
							
							tempConvs.append(Conversation(id: convKey, receriver: receiver, lastMessage: lastMsg, lastMessageTime: Double(lastMsgTime)!))
						}
					}
				}
				
				fetchPublicUserGroup.notify(queue: .main) {
					fetchConversationGroup.leave()
				}
			}
		}
		
		fetchConversationGroup.notify(queue: .main) {
			completion(tempConvs, errorMessage)
		}
	}
	
	func sendMsgTo(receiverId: String, with msg: Message) {
		
		// send message to firebase database
		let conv = ["Sender ID": currentUser.userId,
					 "Message": msg.content]
		
		// make sure we have the same order for convkey between two people
		var convKey: String = ""
		if receiverId < currentUser.userId {
			convKey = receiverId + currentUser.userId
		}else {
			convKey = currentUser.userId + receiverId
		}
		
		let convUpdates = ["\(convKey)/\(Int(msg.timeStamp))": conv]
		conversationRef.updateChildValues(convUpdates)
		
		// send push notification to norificationRequest field in firebase that is observed by node.js server which will observe the change and then route the message to our receiver
		let notificationKey = notificationRef.childByAutoId().key
		let notification = ["message": msg.content, "receiverId": receiverId, "senderId": currentUser.userId]
		
		let notificationUpdate = [notificationKey: notification]
		notificationRef.updateChildValues(notificationUpdate)
	}
	
	func fetchFriends(completion: @escaping FetchUsersResultHandler) {
		var errorMessage: String?
		var tempFriends: [PublicUser] = []
		let friendsRef = publicUserRef.child(currentUser.userId).child("Following")
		let fetchFriendsGroup = DispatchGroup()
		
		friendsRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
			guard let strongSelf = self else { return }
			// check if we have friends
			if let friends = snapshot.value as? [String: String] {
				for (_, friendId) in friends {
					
					// get each friend info and construct an obj out of it
					fetchFriendsGroup.enter()
					strongSelf.fetchPublicUser(with: friendId) { (user, error) in
						fetchFriendsGroup.leave()
						if let friend = user, error == nil {
							tempFriends.append(friend)
						} else {
							errorMessage = (errorMessage ?? "") + error!
						}
					}
				}
			} else {
				errorMessage = "You have no friends"
				completion(nil, errorMessage)
			}
			
			fetchFriendsGroup.notify(queue: .main) {
				completion(tempFriends, errorMessage)
			}
		}
	}
	
	func friendOrUnfriend(with targetUsrId: String) {
		let key = publicUserRef.childByAutoId().key
		let followingsRef = publicUserRef.child(currentUser.userId).child("Following")
		var isFollowing = false
		
		followingsRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
			guard let strongSelf = self else { return }
			
			if let followings = snapshot.value as? [String: Any] {
				// if there are anyone we are following
				for (ke, value) in followings {
					if value as! String == targetUsrId {
						isFollowing = true
						// we already followed him, unfollow instead
						followingsRef.child(ke).removeValue()
						strongSelf.publicUserRef.child(targetUsrId).child("Followers/\(ke)").removeValue()
					}
				}
			}
			
			if !isFollowing {
				// we need to follow this user
				let following = [key: targetUsrId]
				let follower = ["Followers/\(key)": strongSelf.currentUser.userId]
				followingsRef.updateChildValues(following)
				strongSelf.publicUserRef.child(targetUsrId).updateChildValues(follower as Any as! [AnyHashable : Any])
			}
		}
	}
	
	func fetchAllUsers(completion: @escaping FetchUsersResultHandler) {
		var errorMessage: String?
		let fetchUserGroup = DispatchGroup()
		var tempUsers: [PublicUser] = []
		
		publicUserRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
			guard let strongSelf = self else { return }
			guard let userIds = (snapshot.value as? [String: Any])?.keys else {
				errorMessage = "No User Found"
				completion(nil, errorMessage)
				return
			}
			
			for userId in userIds {
				if userId == strongSelf.currentUser.userId {
					continue
				}
				
				fetchUserGroup.enter()
				strongSelf.fetchPublicUser(with: userId) { (pubUser, error) in
					fetchUserGroup.leave()
					if let user = pubUser, error == nil {
						tempUsers.append(user)
					} else {
						errorMessage = (errorMessage ?? "") + error!
					}
				}
			}
			
			fetchUserGroup.notify(queue: .main) {
				completion(tempUsers, errorMessage)
			}
		}
	}
}
