//
//  ShowLikesViewController.swift
//  Instakilo
//
//  Created by Mark on 1/12/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SDWebImage

class ShowLikesViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    
    var postId: String?
    
    private var likedUsers = [PublicUser]() {
        didSet {
            tableview.reloadData()
        }
    }
    
    private lazy var dbRef = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		if let id = postId {
			fetchLikedUsersBy(postId: id)
		}
    }

    private func setupUI() {
		navigationItem.title = "Likes"
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    private func fetchLikedUsersBy(postId: String) {
        self.likedUsers.removeAll()
        
        let postLikedRef = dbRef.child("Posts/\(postId)/Liked By")
        let publicRef = dbRef.child("Public Users")
        
        if let userID = Auth.auth().currentUser?.uid {
            postLikedRef.observeSingleEvent(of: .value) { (snapshot) in
                if let likedUserDict = snapshot.value as? [String: String] {
                    for (_, likedUserId) in likedUserDict {
                        // fetch public user info for this likedUserId
                        publicRef.child(likedUserId).observeSingleEvent(of: .value){ (snapshot) in
                            if let publicUserDict = snapshot.value as? [String: Any],
                                let fullname = publicUserDict["Full Name"] as? String,
                                let username = publicUserDict["Username"] as? String,
                                let profileUrlStr = publicUserDict["Profile Photo"] as? String,
                                let profileUrl = URL(string: profileUrlStr) {
                                
                                let publicUser = PublicUser(fullname: fullname, id: likedUserId, username: username, photoUrl: profileUrl, following: nil, followers: nil)
                                
                                self.likedUsers.append(publicUser)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension ShowLikesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likedUsers.count
    }
	
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        
        let currentUser = likedUsers[indexPath.row]
        cell.fullnameLabel.text = currentUser.fullname
        cell.usernameLabel.text = currentUser.username
        cell.userImageView.sd_setImage(with: currentUser.photoUrl, completed: nil)
        
        // TODO: Check is followed, or following
        
        return cell
    }
}
