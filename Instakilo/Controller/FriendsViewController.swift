//
//  FriendsViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SVProgressHUD

class FriendsViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    
    var friends = [PublicUser]() {
        didSet {
            tableview.reloadData()
        }
    }
	
	private var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
		print("Load Friend VC")
		setupUI()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fetchFriends()
	}
	
	private func setupUI() {
		refreshControl.isEnabled = true
		refreshControl.tintColor = UIColor.red
		refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
		
		tableview.rowHeight = UITableViewAutomaticDimension
		tableview.estimatedRowHeight = 70
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
		tableview.addSubview(refreshControl)
		
	}

	private func fetchFriends() {
		showIndicators()
		FIRAppService.shareInstance.fetchFriends { (users, error) in
			DispatchQueue.main.async {
				self.hideIndicators()
				self.refreshControl.endRefreshing()
			}
			
			guard let friends = users, error == nil else {
				print(error!)
				return
			}
			self.friends = friends
		}
	}
	
	@objc func refreshAction() {
		fetchFriends()
	}
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FriendTableViewCell
		
		let currentFriend = friends[indexPath.row]
		cell.configure(with: currentFriend)
		
        return cell
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let currentFriend = friends[indexPath.row]

		// swift to chattableview controller
		tabBarController?.selectedIndex = 3
		
		// push a chatviewcontroller onto it's navagation controller stack
		if let chatNav = tabBarController?.childViewControllers[3] as? UINavigationController{
			let chatStoryboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
			let chatVc = chatStoryboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
			chatNav.pushViewController(chatVc, animated: true)
			chatVc.receiver = currentFriend
		}
	}
}
