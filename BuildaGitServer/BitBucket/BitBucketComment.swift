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
    
    required init(json: NSDictionary) {
        
        self.body = json
            .optionalDictionaryForKey("content")?
            .stringForKey("raw") ?? json.stringForKey("content")
        
        super.init(json: json)
    }
    
    
}
