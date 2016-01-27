//
//  BitBucketIssue.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketIssue: BitBucketEntity, IssueType {
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
    
    var number: Int = 0
}