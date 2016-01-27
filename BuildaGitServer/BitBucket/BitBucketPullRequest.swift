//
//  BitBucketPullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketPullRequest: BitBucketIssue, PullRequestType {
    
    required init(json: NSDictionary) {
        
        self.headRepo = BitBucketRepo(json: NSDictionary())
        
        super.init(json: json)
    }
    
    var headName: String = ""
    var headCommitSHA: String = ""
    var headRepo: RepoType
    var baseName: String = ""
    var title: String = ""
}
