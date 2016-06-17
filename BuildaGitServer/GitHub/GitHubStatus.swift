//
//  Status.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

class GitHubStatus : GitHubEntity {
    
    enum GitHubState : String {
        case NoState = ""
        case Pending = "pending"
        case Success = "success"
        case Error = "error"
        case Failure = "failure"
        
        static func fromBuildState(buildState: BuildState) -> GitHubState {
            switch buildState {
            case .NoState:
                return .NoState
            case .Pending:
                return .Pending
            case .Success:
                return .Success
            case .Error:
                return .Error
            case .Failure:
                return .Failure
            }
        }
        
        func toBuildState() -> BuildState {
            switch self {
            case .NoState:
                return .NoState
            case .Pending:
                return .Pending
            case .Success:
                return .Success
            case .Error:
                return .Error
            case .Failure:
                return .Failure
            }
        }
    }
    
    let githubState: GitHubState
    let description: String?
    let targetUrl: String?
    let context: String?
    let created: String?
    let creator: GitHubUser?

    required init(json: NSDictionary) throws {
        
        self.githubState = GitHubState(rawValue: try json.stringForKey("state"))!
        self.description = json.optionalStringForKey("description")
        self.targetUrl = json.optionalStringForKey("target_url")
        self.context = json.optionalStringForKey("context")
        self.created = json.optionalStringForKey("created_at")
        if let creator = json.optionalDictionaryForKey("creator") {
            self.creator = try GitHubUser(json: creator)
        } else {
            self.creator = nil
        }
        
        try super.init(json: json)
    }
    
    init(state: GitHubState, description: String?, targetUrl: String?, context: String?) {
        
        self.githubState = state
        self.description = description
        self.targetUrl = targetUrl
        self.context = context
        self.creator = nil
        self.created = nil
        
        super.init()
    }
    
    override func dictionarify() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary["state"] = self.githubState.rawValue
        dictionary.optionallyAddValueForKey(self.description, key: "description")
        dictionary.optionallyAddValueForKey(self.targetUrl, key: "target_url")
        dictionary.optionallyAddValueForKey(self.context, key: "context")
        
        return dictionary
    }
}

extension GitHubStatus: StatusType {
    
    var state: BuildState {
        return self.githubState.toBuildState()
    }
}