//
//  BitBucketEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol BitBucketType {
    init(json: NSDictionary)
}

class BitBucketEntity : BitBucketType {
    
    required init(json: NSDictionary) {
        
        //add any common keys to be parsed here
    }
    
    init() {
        
        //
    }
    
    func dictionarify() -> NSDictionary {
        assertionFailure("Must be overriden by subclasses that wish to dictionarify their data")
        return NSDictionary()
    }
    
    class func optional<T: BitBucketEntity>(json: NSDictionary?) -> T? {
        if let json = json {
            return T(json: json)
        }
        return nil
    }
    
}

//parse an array of dictionaries into an array of parsed entities
func BitBucketArray<T where T: BitBucketType>(jsonDict: NSDictionary) -> [T] {
    
    let array = jsonDict["values"] as! [NSDictionary]!
    let parsed = array.map {
        (json: NSDictionary) -> (T) in
        return T(json: json)
    }
    return parsed
}
