//
//  GitHubEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol GitHub {
    init(json: NSDictionary)
}

class GitHubEntity : GitHub {
    
    let htmlUrl: String?
    let url: String?
    let id: Int?
    
    //initializer which takes a dictionary and fills in values for recognized keys
    required init(json: NSDictionary) {
        
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
    
    class func optional<T: GitHubEntity>(json: NSDictionary?) -> T? {
        if let json = json {
            return T(json: json)
        }
        return nil
    }
    
}

//parse an array of dictionaries into an array of parsed entities
func GitHubArray<T where T:GitHub>(jsonArray: NSArray!) -> [T] {
    
    let array = jsonArray as! [NSDictionary]!
    let parsed = array.map {
        (json: NSDictionary) -> (T) in
        return T(json: json)
    }
    return parsed
}


