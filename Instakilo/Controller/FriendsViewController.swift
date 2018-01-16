//
//  FriendsViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SVProgressHUD

class FriendsViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    
    private var dbRef = Database.database().reference()

    var friends = [PublicUser]() {
        didSet {
            tableview.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Load Friend VC")
        tableview.rowHeight = UITableViewAutomaticDimension
        tableview.estimatedRowHeight = 70
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchFriends()
    }
    
    private func fetchFriends() {
        let currentUid = Auth.auth().currentUser!.uid
        let publicUserRef = dbRef.child("Public Users")
        self.friends.removeAll()
        
        publicUserRef.child(currentUid).child("Following").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot) in
            if let friends = snapshot.value as? [String: String] {
                // if we have friends
                for (_, friendId) in friends {
                    // get each friend info and construct an obj out of it
                    self.constrcutUser(with: friendId)
                }
            } else {
                print("You have no friends")
            }
        }
    }
    
    private func constrcutUser(with id: String){
        let publicUserRef = dbRef.child("Public Users")
        publicUserRef.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let usersDict = snapshot.value as? [String: Any] {
            
                let fullname = usersDict["Full Name"] as! String
                let username = usersDict["Username"] as! String
                let photoUrlStr = usersDict["Profile Photo"] as! String
                
                self.friends.append(PublicUser(fullname: fullname, id: id, username: username, photoUrl: URL(string: photoUrlStr), following: nil, followers: nil))
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FriendTableViewCell
        let currentFriend = friends[indexPath.row]
        
        cell.friendImageVIew.sd_setImage(with: currentFriend.photoUrl, completed: nil)
        cell.usernameLabel.text = currentFriend.username
        cell.fullnameLabel.text = currentFriend.fullname
        
        return cell
    }
}
