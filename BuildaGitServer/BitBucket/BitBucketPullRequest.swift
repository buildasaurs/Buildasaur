//
//  BitBucketPullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketPullRequest: BitBucketIssue, PullRequestType {
    
    let title: String
    let source: BitBucketPullRequestBranch
    let destination: BitBucketPullRequestBranch
    
    required init(json: NSDictionary) throws {
        
        self.title = try json.stringForKey("title")
        
        self.source = try BitBucketPullRequestBranch(json: try json.dictionaryForKey("source"))
        self.destination = try BitBucketPullRequestBranch(json: try json.dictionaryForKey("destination"))
        
        try super.init(json: json)
    }
    
    var headName: String {
        return self.source.branch
    }
    
    var headCommitSHA: String {
        return self.source.commit
    }
    
    var headRepo: RepoType {
        return self.source.repo
    }
    
    var baseName: String {
        return self.destination.branch
    }
}
