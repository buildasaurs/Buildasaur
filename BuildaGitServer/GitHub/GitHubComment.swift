//
//  GitHubComment.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubComment : GitHubEntity {
    
    let body: String
    let author: User
    
    required init(json: NSDictionary) {
        
        self.body = json.stringForKey("body")
        self.author = User(json: json.dictionaryForKey("user"))

        super.init(json: json)
    }
}

extension GitHubComment: CommentType {
    
}
