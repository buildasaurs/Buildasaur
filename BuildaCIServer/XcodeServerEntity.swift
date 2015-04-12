//
//  XcodeServerEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public protocol XcodeRead {
    init(json: NSDictionary)
}

public class XcodeServerEntity : XcodeRead {
    
    public let id: String!
    public let rev: String!
    public let tinyID: String!
    
    //initializer which takes a dictionary and fills in values for recognized keys
    public required init(json: NSDictionary) {
        
        self.id = json.optionalStringForKey("_id")
        self.rev = json.optionalStringForKey("_rev")
        self.tinyID = json.optionalStringForKey("tinyID")
    }
    
    public init() {
        self.id = nil
        self.rev = nil
        self.tinyID = nil
    }
    
    public func dictionarify() -> NSDictionary {
        assertionFailure("Must be overriden by subclasses that wish to dictionarify their data")
        return NSDictionary()
    }
    
    public class func optional<T: XcodeRead>(json: NSDictionary?) -> T? {
        if let json = json {
            return T(json: json)
        }
        return nil
    }
}

//parse an array of dictionaries into an array of parsed entities
public func XcodeServerArray<T where T:XcodeRead>(jsonArray: NSArray!) -> [T] {
    
    let array = jsonArray as! [NSDictionary]!
    let parsed = array.map {
        (json: NSDictionary) -> (T) in
        return T(json: json)
    }
    return parsed
}

