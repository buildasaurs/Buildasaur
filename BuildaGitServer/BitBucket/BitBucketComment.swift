//
//  BitBucketComment.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketComment: BitBucketEntity, CommentType {
    
    let body: String
    
    required init(json: NSDictionary) throws {
        
        if let body = try json
            .optionalDictionaryForKey("content")?
            .stringForKey("raw") {
            self.body = body
        } else {
            self.body = try json.stringForKey("content")
        }
        
        try super.init(json: json)
    }
}
