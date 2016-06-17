//
//  BitBucketEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol BitBucketType {
    init(json: NSDictionary) throws
}

class BitBucketEntity : BitBucketType {
    
    required init(json: NSDictionary) throws {
        
        //add any common keys to be parsed here
    }
    
    init() {
        
        //
    }
    
    func dictionarify() -> NSDictionary {
        assertionFailure("Must be overriden by subclasses that wish to dictionarify their data")
        return NSDictionary()
    }
    
    class func optional<T: BitBucketEntity>(json: NSDictionary?) throws -> T? {
        if let json = json {
            return try T(json: json)
        }
        return nil
    }
    
}

//parse an array of dictionaries into an array of parsed entities
func BitBucketArray<T where T: BitBucketType>(jsonArray: [NSDictionary]) throws -> [T] {
    
    let parsed = try jsonArray.map {
        (json: NSDictionary) -> (T) in
        return try T(json: json)
    }
    return parsed
}
