//
//  GitHubIssue.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubIssue : GitHubEntity {
    
    let number: Int
    let body: String
    var title: String
    
    required init(json: NSDictionary) throws {
        self.number = try json.intForKey("number")
        self.body = json.optionalStringForKey("body") ?? ""
        self.title = try json.stringForKey("title")
        try super.init(json: json)
    }
}


