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
            .dictionaryForKey("content")
            .stringForKey("raw")
        
        super.init(json: json)
    }
    
    
}
