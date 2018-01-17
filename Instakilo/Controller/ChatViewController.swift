//
//  ChatViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

// TODO: emoji keyboard bugs

import UIKit

class ChatViewController: UIViewController {
	@IBOutlet weak var msgViewButtonConstraint: NSLayoutConstraint!
	@IBOutlet weak var msgTextField: UITextField!
	@IBOutlet weak var tableview: UITableView!
	
	var isSending: Bool = false
	var msgQueue = [(String, Bool)]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configureUI()
		setUpNotification()
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
		
		return configureCell(cell: cell, indexPath: indexPath)
	}
	
	private func configureCell(cell: MsgTableViewCell, indexPath: IndexPath) -> UITableViewCell {
		// get current msg
		let (msg, sender) = msgQueue[indexPath.row]
		
		// configure cell
		cell.receiverCellShadowView.isHidden = !cell.receiverCellShadowView.isHidden
		cell.senderCellShadowView.isHidden = !cell.senderCellShadowView.isHidden
		
		if sender {
			cell.receiverCellShadowView.isHidden = true
			cell.receiverMsgTextView.isHidden = true
			
			cell.senderMsgTextView.text = msg
			cell.textLabel?.text = " "
			
			cell.senderCellShadowView.isHidden = false
			cell.senderMsgTextView.isHidden = false
		} else {
			
			cell.senderCellShadowView.isHidden = true
			cell.senderMsgTextView.isHidden = true
			
			cell.receiverMsgTextView.text = msg
			cell.detailTextLabel?.text = " "
			
			cell.receiverCellShadowView.isHidden = false
			cell.receiverMsgTextView.isHidden = false
		}
		
		// remove cell edge
		cell.layoutMargins = UIEdgeInsets.zero
		// return cell
		return cell
	}
}

private extension ChatViewController {
	// MARK: - Helper Methods
	private func configureUI() {
		
		// for dismissing keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)
		
		tableview.rowHeight = UITableViewAutomaticDimension
		tableview.estimatedRowHeight = 80
		
		// remove edge
		tableview.layoutMargins = UIEdgeInsets.zero
		tableview.separatorInset = UIEdgeInsets.zero
		
		// Do any additional setup after loading the view.
		view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
	}
	
	private func setUpNotification () {
		// use built in notification name (UIKeyboardWillShow channel) to observe keyboard event
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillhide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
	private func animate() {
		UIView.animate(withDuration: 1.5) {
			self.view.layoutIfNeeded()
		}
	}
	
	private func showAlert(msg: String) {
		let alert = UIAlertController(title: "Msg", message: msg, preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(action)
		present(alert, animated: true, completion: nil)
	}
}

private extension ChatViewController {
	
	// MARK: - Event handle Methods
	@IBAction func submit(_ sender: UIButton) {
		// Do something with input msg, validated text input
		guard let inputText = msgTextField.text else {
			showAlert(msg: "Make sure the text is not empty")
			return
		}
		
		// change current responder
		isSending = !isSending
		
		// add to msgqueue
		msgQueue.append((inputText, isSending))
		
		//clear msg
		msgTextField.text = ""
		
		// hide the keyboard
		msgTextField.resignFirstResponder()
		
		// reload tableview data
		tableview.reloadData()
	}
	
	@objc private func keyboardWillShow(_ notification: Notification) {
		print("The keyboard is about to show, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			msgViewButtonConstraint.constant += keyboardSize.height
			animate()
		}
		
	}
	
	@objc private func keyboardWillhide(_ notification: Notification) {
		print("The keyboard is about to hide, change constarint! ")
		if let userInfo = notification.userInfo,
			let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			msgViewButtonConstraint.constant -= keyboardSize.height
			animate()
		}
	}
	
	@objc private func dismissKeyboard() {
		view.endEditing(true)
	}
}




