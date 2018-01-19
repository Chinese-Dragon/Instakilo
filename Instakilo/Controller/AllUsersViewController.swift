//
//  AllUsersViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SVProgressHUD

class AllUsersViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    var allUsers = [PublicUser]() {
        didSet {
            tableview.reloadData()
        }
    }
    
	private var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fetchAllUsers()
	}
	
	private func setupUI() {
		print("Load USers VC")
		refreshControl.isEnabled = true
		refreshControl.tintColor = UIColor.red
		refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
		
		tableview.rowHeight = UITableViewAutomaticDimension
		tableview.estimatedRowHeight = 70
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
		tableview.addSubview(refreshControl)
	}
	
	@objc func refreshAction() {
		fetchAllUsers()
	}
    
    private func fetchAllUsers() {
		showIndicators()
		FIRAppService.shareInstance.fetchAllUsers { (pubUsers, error) in
			DispatchQueue.main.async {
				self.hideIndicators()
				self.refreshControl.endRefreshing()
			}
			
			guard let users = pubUsers, error == nil else {
				print(error!)
				return
			}
			
			self.allUsers = users
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
		cell.delegate = self
		cell.configure(with: currentPublicUser)
		
        return cell
    }
}

extension AllUsersViewController: UserTableViewCellDelegate {
	func addFriendTapped(_ cell: UserTableViewCell) {
		// get the current indexPath
		guard let indexPath = tableview.indexPath(for: cell) else { return }
		
		// find the current User
		let currentUser = allUsers[indexPath.row]
		
		// add or remove following/ followers from current user
		if cell.friendButton.isSelected {
			// remove this userId from currentuser following
			CurrentUser.sharedInstance.following = CurrentUser.sharedInstance.following.filter { $0 != currentUser.id}
		} else {
			// add this userId add curentUser following
			CurrentUser.sharedInstance.following.append(currentUser.id)
		}
		
		// reload cell so that cell button state can be properly displayed
		tableview.reloadRows(at: [indexPath], with: .none)
		
		// update User friendship status with firebase call
		// friend if not, vice versa
		FIRAppService.shareInstance.friendOrUnfriend(with: currentUser.id)
	}
}
