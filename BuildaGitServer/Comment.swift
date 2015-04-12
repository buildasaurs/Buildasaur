//
//  Comment.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Comment : GitHubEntity {
    
    public let body: String
    public let author: User
    
    public required init(json: NSDictionary) {
        
        self.body = json.stringForKey("body")
        self.author = User(json: json.dictionaryForKey("user"))

        super.init(json: json)
    }
}

