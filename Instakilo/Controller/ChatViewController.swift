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
		conversationRef.observe(.value) { (snapshot) in
			guard let msgDicts = snapshot.value as? [String: Any] else { return }
			self.msgQueue.removeAll()
			for (msgTime, msgBody) in msgDicts {
				if let msgContent = (msgBody as? [String: String])?["Message"],
					let msgSenderId = (msgBody as? [String: String])?["Sender ID"] {
					
					let newMessage = Message(content: msgContent, timeStamp: Double(msgTime)!)
					let msg = (newMessage, msgSenderId == CurrentUser.sharedInstance.userId)
					DispatchQueue.main.async {
						self.msgQueue.append(msg)
						// scroll tableview to the bottom
					}
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
	
	func finishSendingMessage() {
		//clear msg
		msgTextField.text = ""
		
		// hide the keyboard
		msgTextField.resignFirstResponder()
		
		// reload tableview data
		tableview.reloadData()
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
		
		finishSendingMessage()
	}
	
	@objc func keyboardWillShow(_ notification: Notification) {
		print("The keyboard is about to show, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			msgViewButtonConstraint.constant += keyboardSize.height
			scrollToLastRow()
			animate()
		}
	}
	
	@objc func keyboardWillhide(_ notification: Notification) {
		print("The keyboard is about to hide, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			msgViewButtonConstraint.constant -= keyboardSize.height
			animate()
		}
	}
	
	@objc func dismissKeyboard() {
		view.endEditing(true)
	}
}




