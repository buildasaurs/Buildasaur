//
//  GitHubBranch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

//PullRequestBranch is a special type of a branch - it also includes repo info (bc PRs can be cross repos)
//normal branches include less information
class GitHubPullRequestBranch : GitHubEntity {
    
    let ref: String
    let sha: String
    let repo: GitHubRepo
    
    required init(json: NSDictionary) throws {
        
        self.ref = try json.stringForKey("ref")
        self.sha = try json.stringForKey("sha")
        guard let repo = json.optionalDictionaryForKey("repo") else {
            throw Error.withInfo("PR missing information about its repository")
        }
        self.repo = try GitHubRepo(json: repo)
        
        try super.init(json: json)
    }
}

