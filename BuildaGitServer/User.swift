//
//  User.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class User : GitHubEntity {

    public let userName: String
    public let realName: String?
    public let avatarUrl: String?

    public required init(json: NSDictionary) {
        
        self.userName = json.stringForKey("login")
        self.realName = json.optionalStringForKey("name")
        self.avatarUrl = json.stringForKey("avatar_url")
        
        super.init(json: json)
    }
}

