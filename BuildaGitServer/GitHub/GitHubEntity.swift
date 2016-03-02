//
//  GitHubEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol GitHubType {
    init(json: NSDictionary) throws
}

class GitHubEntity : GitHubType {
    
    let htmlUrl: String?
    let url: String?
    let id: Int?
    
    //initializer which takes a dictionary and fills in values for recognized keys
    required init(json: NSDictionary) throws {
        
        self.htmlUrl = json.optionalStringForKey("html_url")
        self.url = json.optionalStringForKey("url")
        self.id = json.optionalIntForKey("id")
    }
    
    init() {
        self.htmlUrl = nil
        self.url = nil
        self.id = nil
    }
    
    func dictionarify() -> NSDictionary {
        assertionFailure("Must be overriden by subclasses that wish to dictionarify their data")
        return NSDictionary()
    }
    
    class func optional<T: GitHubEntity>(json: NSDictionary?) throws -> T? {
        if let json = json {
            return try T(json: json)
        }
        return nil
    }
    
}

//parse an array of dictionaries into an array of parsed entities
func GitHubArray<T where T: GitHubType>(jsonArray: NSArray!) throws -> [T] {
    
    let array = jsonArray as! [NSDictionary]
    let parsed = try array.map {
        (json: NSDictionary) -> (T) in
        return try T(json: json)
    }
    return parsed
}


