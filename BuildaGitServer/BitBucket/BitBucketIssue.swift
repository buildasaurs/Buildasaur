//
//  BitBucketIssue.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketIssue: BitBucketEntity, IssueType {
    
    let number: Int
    
    required init(json: NSDictionary) throws {
        
        self.number = try json.intForKey("id")
        
        try super.init(json: json)
    }
}