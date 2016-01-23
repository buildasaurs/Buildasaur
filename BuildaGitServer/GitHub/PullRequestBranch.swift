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
class PullRequestBranch : GitHubEntity {
    
    let ref: String
    let sha: String
    let repo: Repo
    
    required init(json: NSDictionary) {
        
        self.ref = json.stringForKey("ref")
        self.sha = json.stringForKey("sha")
        self.repo = Repo(json: json.dictionaryForKey("repo"))
        
        super.init(json: json)
    }
}

