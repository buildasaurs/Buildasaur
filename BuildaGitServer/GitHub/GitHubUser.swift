//
//  User.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubUser : GitHubEntity {

    let userName: String
    let realName: String?
    let avatarUrl: String?

    required init(json: NSDictionary) throws {
        
        self.userName = json.stringForKey("login")
        self.realName = json.optionalStringForKey("name")
        self.avatarUrl = json.stringForKey("avatar_url")
        
        try super.init(json: json)
    }
}

