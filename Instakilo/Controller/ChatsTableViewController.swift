//
//  ChatsTableViewController.swift
//  Instakilo
//
//  Created by Mark on 1/17/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ChatsTableViewController: UIViewController {

	@IBOutlet weak var tableview: UITableView!
	
	var conversations: [Conversation] = [] {
		didSet {
			tableview.reloadData()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
    }
	
	private func setupUI() {
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
		
		tableview.rowHeight = UITableViewAutomaticDimension
		tableview.estimatedRowHeight = 70
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// fetch conversation data
		FIRAppService.shareInstance.fetchConversation { (newConversations, error) in
			guard error == nil, let convs = newConversations else {
				print(error!)
				return
			}
			
			DispatchQueue.main.async {
				self.conversations = convs
			}
		}
	}
	
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showChatSegue", let targetVC = segue.destination as? ChatViewController, let indexPath = tableview.indexPathForSelectedRow {
			
			targetVC.receiver = conversations[indexPath.row].receriver
		}
    }
}

extension ChatsTableViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return conversations.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableview.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
		
		let currentConversation = conversations[indexPath.row]
		cell.configure(with: currentConversation)
		
		return cell
	}
}
