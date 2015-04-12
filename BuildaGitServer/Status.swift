//
//  Status.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class Status : GitHubEntity, Equatable {
    
    public enum State : String {
        case NoState = ""
        case Pending = "pending"
        case Success = "success"
        case Error = "error"
        case Failure = "failure"
    }
    
    public let state: State
    public let description: String?
    public let targetUrl: String?
    public let context: String?
    public let created: String?
    public let creator: User?

    public required init(json: NSDictionary) {
        
        self.state = State(rawValue: json.stringForKey("state"))!
        self.description = json.optionalStringForKey("description")
        self.targetUrl = json.optionalStringForKey("target_url")
        self.context = json.optionalStringForKey("context")
        self.created = json.optionalStringForKey("created_at")
        if let creator = json.optionalDictionaryForKey("creator") {
            self.creator = User(json: creator)
        } else {
            self.creator = nil
        }
        
        super.init(json: json)
    }
    
    public init(state: State, description: String?, targetUrl: String?, context: String?) {
        
        self.state = state
        self.description = description
        self.targetUrl = targetUrl
        self.context = context
        self.creator = nil
        self.created = nil
        
        super.init()
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dictionary = NSMutableDictionary()
        
        dictionary["state"] = self.state.rawValue
        dictionary.optionallyAddValueForKey(self.description, key: "description")
        dictionary.optionallyAddValueForKey(self.targetUrl, key: "target_url")
        dictionary.optionallyAddValueForKey(self.context, key: "context")
        
        return dictionary
    }
}

public func ==(lhs: Status, rhs: Status) -> Bool {
    return lhs.state == rhs.state && lhs.description == rhs.description
}

//for sending statuses upstream
extension Status {
        
    public class func toDict(state: State, description: String? = nil, targetUrl: String? = nil, context: String? = nil) -> [String: String] {
        return [
            "state" : state.rawValue,
            "target_url" : targetUrl ?? "",
            "description" : description ?? "",
            "context" : context ?? ""
        ]
    }
    
}
