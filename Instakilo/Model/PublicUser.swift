//
//  PublicUser.swift
//  Instakilo
//
//  Created by Mark on 1/8/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation

struct PublicUser {
    var fullname: String?
    var id: String
    var username: String?
    var photoUrl: URL?
    var following: [Int]?
    var followers: [Int]?
}
