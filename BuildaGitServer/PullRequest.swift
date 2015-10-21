//
//  PullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class PullRequest : Issue {
    
    let head: PullRequestBranch
    let base: PullRequestBranch
    
    required init(json: NSDictionary) {
        
        self.head = PullRequestBranch(json: json.dictionaryForKey("head"))
        self.base = PullRequestBranch(json: json.dictionaryForKey("base"))
        
        super.init(json: json)
    }
}

extension PullRequest: PullRequestType {
    
    var headName: String {
        return self.head.ref
    }
    
    var headCommitSHA: String {
        return self.head.sha
    }
    
    var headRepo: RepoType {
        return self.head.repo
    }
}
