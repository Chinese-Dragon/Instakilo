//
//  HomeViewController.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import UIKit
import SDWebImage

// TimeStamp https://stackoverflow.com/questions/29243060/trying-to-convert-firebase-timestamp-to-nsdate-in-swift/30244373#30244373

class HomeViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    var posts = [Post]() {
        didSet {
            if view.window != nil {
                // sort by chronically order
                posts.sort { $0.postTime > $1.postTime }
                tableview.reloadData()
            }
        }
    }
    
    private lazy var fireService = FIRAppService.shareInstance
    private var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchFeeds()
		
		// TODO: move to splash screen
		fireService.fetchCurrentUserData(completion: nil)
    }
    
    @objc func refreshAction() {
        fetchFeeds()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addPostSegue", let targetVC = segue.destination.contents as? AddPostViewController {
            targetVC.delegate = self
        }
    }
}

// MARK: Private Helper Methods
private extension HomeViewController {
    func setupUI() {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "patternBackground")!)
        refreshControl.isEnabled = true
        refreshControl.tintColor = UIColor.red
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        tableview.addSubview(refreshControl)
        tableview.rowHeight = UITableViewAutomaticDimension
        tableview.estimatedRowHeight = 520
    }
    
    func fetchFeeds() {
        showIndicators()
        fireService.fetchFeeds { (posts, error) in
            if let unwrappedPost = posts, error == nil {
                DispatchQueue.main.async {
                    self.hideIndicators()
					self.refreshControl.endRefreshing()
                    self.posts = unwrappedPost
                }
            }
        }
    }
}

// MARK: - Tableview Delegation Methods
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        
        let currentPost = posts[indexPath.row]
        cell.delegate = self
        cell.configure(post: currentPost)
        
        return cell
    }
}

// MARK: - AddPostVC Delegation Method
extension HomeViewController: AddPostViewControllerDelegate {
    func didPostFeed() {
        fetchFeeds()
    }
}

// MARK: - PostCellDelegate
extension HomeViewController: PostTableViewCellDelegate {
    func likeTapped(_ cell: PostTableViewCell) {
        // get the current Index path
        let indexPath = tableview.indexPath(for: cell)!
        
        // find the post with PostID
        let currentPost = posts[indexPath.row]
        
        // update the current post regarding current cell status
        currentPost.isLiked = cell.likeButton.isSelected
        currentPost.postLikeCount = cell.likeButton.isSelected ?
                                    currentPost.postLikeCount + 1 :
                                    currentPost.postLikeCount - 1
        
        tableview.reloadRows(at: [indexPath], with: .none)
        
        // update post like status with firebase call
        // like it if not, vice versa
        fireService.likeOrUnlikePost(with: currentPost.postId)
    }
    
    func shareTapped(_ cell: PostTableViewCell) {
        // TODO: Implement share
    }
    
    func likeCountTapped(_ cell: PostTableViewCell) {
        guard let indexPath = tableview.indexPath(for: cell) else { return }
        let currentPost = posts[indexPath.row]
        
        if let targetVC = storyboard?.instantiateViewController(withIdentifier: "ShowLikesViewController") as? ShowLikesViewController {
            targetVC.postId = currentPost.postId
            targetVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(targetVC, animated: true)
        }
    }
    
    func viewCommentsTapped(_ cell: PostTableViewCell) {
        guard let indexPath = tableview.indexPath(for: cell) else { return }
        let currentPost = posts[indexPath.row]
        
        if let targetVC = storyboard?.instantiateViewController(withIdentifier: "AddCommentViewController") as? AddCommentViewController {
            targetVC.postId = currentPost.postId
            targetVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(targetVC, animated: true)
        }
    }
}

