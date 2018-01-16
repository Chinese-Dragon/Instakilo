//
//  CurrentUser.swift
//  Instakilo
//
//  Created by Mark on 1/6/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation
import UIKit

class CurrentUser: NSObject {
	static let shareInstance = CurrentUser()
	private override init() {}
	
	var userId: String!
	var email: String!
	var fullname: String?
	var password: String?
	var profileImageUrl: URL?
	var username: String?
	var website: String?
	var bio: String?
	var phoneNumber: String?
	var gender: String?
	var posts: [String] = []
	var following: [String] = []
	var follwers: [String] = []
}


