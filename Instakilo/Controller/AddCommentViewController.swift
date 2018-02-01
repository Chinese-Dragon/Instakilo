//
//  AddCommentViewController.swift
//  Instakilo
//
//  Created by Mark on 1/11/18.
//  Copyright © 2018 Mark. All rights reserved.
//

/********** Need to spend a LOT of time practicing GCD/NSOperation with multiple webservices ***********
*/

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SDWebImage

class AddCommentViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var inputTextBottomConstraint: NSLayoutConstraint!
    
    typealias CommentResultHandler = ([Comment]?) -> ()
    typealias CommentDictionary = [String: String]
    
    var postId: String?
    
    private var comments = [Comment]() {
        didSet {
            if view.window != nil, comments.count == totalComments {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                tableview.reloadData()
            }
        }
    }
    private var totalComments = -1
    private lazy var dbRef = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpNotification()
        
        if let id = postId {
            fetchComments(of: id)
        }
    }
    
    private func setupUI() {
        navigationItem.title = "Comments"
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tableview.addGestureRecognizer(tap)
    }
    
    // fetch comments regard the current post
    private func fetchComments(of postId: String) {
        // start fetching
        self.comments.removeAll()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let commentsRef = dbRef.child("Posts/\(postId)/Comments")
        commentsRef.observeSingleEvent(of: .value){ (snapshot) in
            if let comments = snapshot.value as? [String: Any] {
                self.totalComments = comments.count
                for (commentId, commentDictionary) in comments {
                    if let commentDict = commentDictionary as? CommentDictionary {
                        let comment = commentDict["Comment"]!
                        let commenterId = commentDict["Commenter"]!
                        
                        // fetch public userPhoto url
                        self.dbRef.child("Public Users/\(commenterId)/Profile Photo").observeSingleEvent(of: .value) { (snapshot) in
                            if let urlStr = snapshot.value as? String, let url = URL(string: urlStr) {
                                
                                let newComment = Comment(id: commentId, commenterId: commenterId, commenterPhotoUrl: url, commentContent: comment)
                                self.comments.append(newComment)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addNewComment(to postId: String, with comment: String) {
        let currentUserId = Auth.auth().currentUser!.uid
        let commentsRef = dbRef.child("Posts/\(postId)/Comments")
        let publicUserRef = dbRef.child("Public Users/\(currentUserId)/Profile Photo")
        let newCommentID = commentsRef.childByAutoId().key
        
        let newComment = ["Comment": comment,
                          "Commenter": currentUserId]
        
        commentsRef.child(newCommentID).updateChildValues(newComment) { (error, ref) in
            guard error == nil else { return }
            publicUserRef.observeSingleEvent(of: .value){ (snapshot) in
                if let urlStr = snapshot.value as? String, let url = URL(string: urlStr) {
                    let newComment = Comment(id: newCommentID, commenterId: currentUserId, commenterPhotoUrl: url, commentContent: comment)
                    self.comments.append(newComment)
                    DispatchQueue.main.async {
                        self.tableview.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func sendComment(_ sender: UIButton) {
        guard let id = postId else { return }
        addNewComment(to: id, with: inputTextField.text!)
    }
    
    private func setUpNotification () {
        // use built in notification name (UIKeyboardWillShow channel) to observe keyboard event
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillhide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        print("The keyboard is about to show, change constarint! ")
        if let userInfo = notification.userInfo,
            let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            inputTextBottomConstraint.constant += keyboardSize.height
            animate()
        }
        
    }
    
    @objc private func keyboardWillhide(_ notification: Notification) {
        print("The keyboard is about to hide, change constarint! ")
        if let userInfo = notification.userInfo,
            let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            inputTextBottomConstraint.constant -= keyboardSize.height
            animate()
        }
    }
    
    private func animate() {
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
        }
    }
}

extension AddCommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
        
        let currentComment = comments[indexPath.row]
        cell.userImageView.sd_setImage(with: currentComment.commenterPhotoUrl, completed: nil)
        cell.commentContent.text = currentComment.commentContent
        
        return cell
    }
}
