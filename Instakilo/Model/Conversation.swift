//
//  Conversation.swift
//  Instakilo
//
//  Created by Mark on 1/17/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation

struct Conversation {
	var id: String
	var receriver: PublicUser
	var lastMessage: String
	var lastMessageTime: Double
}
