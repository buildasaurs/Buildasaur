//
//  BitBucketPullRequestBranch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketPullRequestBranch : BitBucketEntity {
    
    let branch: String
    let commit: String
    let repo: BitBucketRepo
    
    required init(json: NSDictionary) {
        
        self.branch = json.dictionaryForKey("branch").stringForKey("name")
        self.commit = json.dictionaryForKey("commit").stringForKey("hash")
        self.repo = BitBucketRepo(json: json.dictionaryForKey("repository"))
        
        super.init(json: json)
    }
}