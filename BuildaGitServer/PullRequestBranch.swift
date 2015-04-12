//
//  Branch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

//PullRequestBranch is a special type of a branch - it also includes repo info (bc PRs can be cross repos)
//normal branches include less information
public class PullRequestBranch : GitHubEntity {
    
    public let label: String
    public let ref: String
    public let sha: String
    public let user: User
    public let repo: Repo
    
    public required init(json: NSDictionary) {
        
        self.label = json.stringForKey("label")
        self.ref = json.stringForKey("ref")
        self.sha = json.stringForKey("sha")
        self.user = User(json: json.dictionaryForKey("user"))
        self.repo = Repo(json: json.dictionaryForKey("repo"))
        
        super.init(json: json)
    }
}

