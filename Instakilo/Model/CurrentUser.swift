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
	struct Static {
		static var instance: CurrentUser?
	}
	
	class var sharedInstance: CurrentUser {
		if Static.instance == nil
		{
			Static.instance = CurrentUser()
		}
		
		return Static.instance!
	}
	
	func dispose() {
		CurrentUser.Static.instance = nil
		print("Disposed Singleton instance")
	}
	
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


