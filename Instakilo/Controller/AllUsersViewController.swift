//
//  AllUsersViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseAuth
import FirebaseDatabase
import SVProgressHUD

class AllUsersViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    var allUsers = [PublicUser]() {
        didSet {
            tableview.reloadData()
        }
    }
    
    private var dbRef = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Load USers VC")
        tableview.rowHeight = UITableViewAutomaticDimension
        tableview.estimatedRowHeight = 70
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchAllUsers()
    }
    
    @IBAction func addNRemoveFriend(_ sender: UIButton) {
        
        if let cell = sender.superview?.superview as? UserTableViewCell {
            let indexPath = tableview.indexPath(for: cell)!
            print("I am clicked")
            let currentUid = Auth.auth().currentUser!.uid
            let publicUserRef = dbRef.child("Public Users")
            let key = publicUserRef.childByAutoId().key
            let selectedUserId = self.allUsers[indexPath.row].id
            
            var isFollowing = false
            
            publicUserRef.child(currentUid).child("Following").queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
                if let friends = snapshot.value as? [String: Any] {
                    // if we have following user
                    for (ke, value) in friends {
                        
                        if value as! String == selectedUserId {
                            isFollowing = true
                            // we already followed him, unfollow instead
                            publicUserRef.child(currentUid).child("Following/\(ke)").removeValue()
                            publicUserRef.child(selectedUserId).child("Followers/\(ke)").removeValue()
                            sender.isSelected = false
                        }
                    }
                }
                
                if !isFollowing {
                    // we need to follow this user
                    let following = ["Following/\(key)": self.allUsers[indexPath.row].id]
                    let follower = ["Followers/\(key)": currentUid]
                    publicUserRef.child(currentUid).updateChildValues(following)
                    publicUserRef.child(selectedUserId).updateChildValues(follower)
                    sender.isSelected = true
                }
            })
        }
    }
    
    private func checkingFriendship(with indexPath: IndexPath) {
        let currentUid = Auth.auth().currentUser!.uid
        let publicUserRef = dbRef.child("Public Users")
        var isFriend = false
        
        publicUserRef.child(currentUid).child("Following").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot) in
            if let friends = snapshot.value as? [String: Any] {
                // if we have friends
                for (_, value) in friends {
                    if value as! String == self.allUsers[indexPath.row].id {
                        // if we already followed the user, change button state
                        isFriend = true
                        (self.tableview.cellForRow(at: indexPath) as! UserTableViewCell).friendButton.isSelected = true
                    }
                }
            }
            
            if !isFriend {
                // we need to friend this user
                (self.tableview.cellForRow(at: indexPath) as! UserTableViewCell).friendButton.isSelected = false
            }
        }
    }
    
    private func fetchAllUsers() {
        var temp = [PublicUser]()
        let publicUserRef = dbRef.child("Public Users")
        
        if let userID = Auth.auth().currentUser?.uid {
            SVProgressHUD.show()
            
            publicUserRef.observeSingleEvent(of: .value, with: { (snapshot) in
                SVProgressHUD.dismiss()
                // Get user value
                if let usersDict = snapshot.value as? [String: Any] {
                    for (id, obj) in usersDict {
                        if id != userID {
                            let fullname = (obj as! [String: Any])["Full Name"] as! String
                            let username = (obj as! [String: Any])["Username"] as! String
                            let photoUrlStr = (obj as! [String: Any])["Profile Photo"] as! String
                            
                            temp.append(PublicUser(fullname: fullname, id: id, username: username, photoUrl: URL(string: photoUrlStr), following: nil, followers: nil))
                        }
                    }
                    
                    self.allUsers = temp
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    
}

extension AllUsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        
        let currentPublicUser = allUsers[indexPath.row]
        cell.userImageView?.sd_setImage(with: currentPublicUser.photoUrl, completed: nil)
        cell.usernameLabel.text = currentPublicUser.username
        cell.fullnameLabel.text = currentPublicUser.fullname
        checkingFriendship(with: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
