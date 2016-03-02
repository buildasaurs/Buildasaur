//
//  GitHubPullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubPullRequest : GitHubIssue, PullRequestType {
    
    let head: GitHubPullRequestBranch
    let base: GitHubPullRequestBranch
    
    required init(json: NSDictionary) throws {
        
        self.head = try GitHubPullRequestBranch(json: json.dictionaryForKey("head"))
        self.base = try GitHubPullRequestBranch(json: json.dictionaryForKey("base"))
        
        try super.init(json: json)
    }
    
    var headName: String {
        return self.head.ref
    }
    
    var headCommitSHA: String {
        return self.head.sha
    }
    
    var headRepo: RepoType {
        return self.head.repo
    }
    
    var baseName: String {
        return self.base.ref
    }
}
