//
//  BitBucketRepo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketRepo: BitBucketEntity, RepoType {
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
    
    var permissions = RepoPermissions(read: true, write: true)
    var originUrlSSH: String = ""
    var latestRateLimitInfo: RateLimitType? = BitBucketRateLimit()
}
