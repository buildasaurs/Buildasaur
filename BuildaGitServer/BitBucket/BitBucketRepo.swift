//
//  BitBucketRepo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketRepo: BitBucketEntity, RepoType {
    
    //kind of pointless here
    let permissions = RepoPermissions(read: true, write: true)
    let latestRateLimitInfo: RateLimitType? = BitBucketRateLimit()
    let originUrlSSH: String
    
    required init(json: NSDictionary) {
        
        //split with forward slash, the last two comps are the repo
        //create a proper ssh url for bitbucket here
        let repoName = json
            .dictionaryForKey("links")
            .dictionaryForKey("self")
            .stringForKey("href")
            .componentsSeparatedByString("/")
            .suffix(2)
            .joinWithSeparator("/")
        self.originUrlSSH = "git@bitbucket.org:\(repoName).git"
        
        super.init(json: json)
    }
}
