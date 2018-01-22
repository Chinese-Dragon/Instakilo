//
//  ChatViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

// TODO: emoji keyboard bugs

import UIKit
import FirebaseDatabase

class ChatViewController: UIViewController {
	@IBOutlet weak var msgViewButtonConstraint: NSLayoutConstraint!
	@IBOutlet weak var msgTextField: UITextField!
	@IBOutlet weak var tableview: UITableView!
	@IBOutlet weak var textFieldWrapper: UIView!
	
	var receiver: PublicUser!
	
	private var msgQueue = [(Message, Bool)]() {
		didSet {
			msgQueue.sort{ $0.0.timeStamp < $1.0.timeStamp }
			tableview.reloadData()
			scrollToLastRow()
		}
	}
	private var conversationRef: DatabaseReference!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureUI()
		setUpKeyboardNotification()
		setUpFirB()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		observeMessages()
	}
	
	private func setUpFirB() {
		var convKey: String = ""
		if receiver.id < CurrentUser.sharedInstance.userId {
			convKey = receiver.id + CurrentUser.sharedInstance.userId
		} else {
			convKey = CurrentUser.sharedInstance.userId + receiver.id
		}
		
		conversationRef = Database.database().reference().child("Conversations/\(convKey)")
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		conversationRef.removeAllObservers()
	}
	
	func observeMessages() {
		// settup data binding for real time update
		// Retrieve lists of items or listen for additions to a list of items. This event is triggered once for each existing child and then again every time a new child is added to the specified path. The listener is passed a snapshot containing the new child's data.
		// this event listener is perfect for our case as it will trigger for each message when first initalize
		conversationRef.observe(.childAdded) { (snapshot) in
			let msgTime = snapshot.key
			guard let msgDicts = snapshot.value as? [String: String] else { return }
			if let msgContent = msgDicts["Message"],
				let msgSenderId = msgDicts["Sender ID"] {
				
				let newMessage = Message(content: msgContent, timeStamp: Double(msgTime)!)
				let msg = (newMessage, msgSenderId == CurrentUser.sharedInstance.userId)
				DispatchQueue.main.async {
					self.msgQueue.append(msg)
				}
			}
		}
	}
}
extension ChatViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return msgQueue.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MsgTableViewCell
		
		let currentMsg = msgQueue[indexPath.row]
		
		cell.configure(with: currentMsg)
		
		return cell
	}
}

// MARK: - Helper Methods
private extension ChatViewController {
	func configureUI() {
		
		navigationItem.title = receiver.username
		
		// for dismissing keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)
		
		tableview.rowHeight = UITableViewAutomaticDimension
		tableview.estimatedRowHeight = 80
		
		// remove edge
		tableview.layoutMargins = UIEdgeInsets.zero
		tableview.separatorInset = UIEdgeInsets.zero
		
		// make round textfield wrapper
		textFieldWrapper.layer.cornerRadius = 15
		textFieldWrapper.layer.borderColor = UIColor.gray.cgColor
		textFieldWrapper.layer.borderWidth = 0.2
		
		// Do any additional setup after loading the view.
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
	}
	
	func setUpKeyboardNotification () {
		// use built in notification name (UIKeyboardWillShow channel) to observe keyboard event
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillhide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
	func animate() {
		UIView.animate(withDuration: 1) {
			self.view.layoutIfNeeded()
		}
	}
	
	func scrollToLastRow() {
		if !msgQueue.isEmpty {
			let indexPath = IndexPath(row: msgQueue.count - 1, section: 0)
			tableview.scrollToRow(at: indexPath, at: .bottom, animated: false)
		}
	}
}

private extension ChatViewController {
	
	// MARK: - Event handle Methods
	@IBAction func submit(_ sender: UIButton) {
		// get current date
		let unixTime = Date().timeIntervalSince1970
		
		// add to msgqueue
		let currentMessage = Message(content: msgTextField.text!, timeStamp: unixTime)
		
		// send msg to firebase
		FIRAppService.shareInstance.sendMsgTo(receiverId: receiver.id, with: currentMessage)
		
		msgTextField.text = ""
	}
	
	@objc func keyboardWillShow(_ notification: Notification) {
		print("The keyboard is about to show, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardHeight = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height {
			msgViewButtonConstraint.constant += keyboardHeight
			
//			let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0)
			scrollToLastRow()
			tableview.setContentOffset(CGPoint(x: 0, y: keyboardHeight), animated: false)
			animate()
		}
	}
	
	@objc func keyboardWillhide(_ notification: Notification) {
		print("The keyboard is about to hide, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			msgViewButtonConstraint.constant -= keyboardSize.height
			animate()
		}
	}
	
	@objc func dismissKeyboard() {
		view.endEditing(true)
	}
}




