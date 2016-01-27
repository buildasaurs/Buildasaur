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
    
    required init(json: NSDictionary) {
        
        self.title = json.stringForKey("title")
        
        self.source = BitBucketPullRequestBranch(json: json.dictionaryForKey("source"))
        self.destination = BitBucketPullRequestBranch(json: json.dictionaryForKey("destination"))
        
        super.init(json: json)
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
