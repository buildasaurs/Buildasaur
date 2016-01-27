//
//  BitBucketStatus.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketStatus: BitBucketEntity, StatusType {
    
    enum BitBucketState: String {
        case InProgress = "INPROGRESS"
        case Success = "SUCCESSFUL"
        case Failed = "FAILED"
    }
    
    let bbState: BitBucketState
    let key: String
    let name: String?
    let description: String?
    let targetUrl: String?
    
    required init(json: NSDictionary) {
        
        self.bbState = BitBucketState(rawValue: json.stringForKey("state"))!
        self.key = json.stringForKey("key")
        self.name = json.optionalStringForKey("name")
        self.description = json.optionalStringForKey("description")
        self.targetUrl = json.stringForKey("url")
        
        super.init(json: json)
    }
    
    init(state: BitBucketState, key: String, name: String?, description: String?, url: String) {
        
        self.bbState = state
        self.key = key
        self.name = name
        self.description = description
        self.targetUrl = url
        
        super.init()
    }
    
    var state: BuildState {
        return self.bbState.toBuildState()
    }
    
    override func dictionarify() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary["state"] = self.bbState.rawValue
        dictionary["key"] = self.key
        dictionary.optionallyAddValueForKey(self.description, key: "description")
        dictionary.optionallyAddValueForKey(self.name, key: "name")
        dictionary.optionallyAddValueForKey(self.targetUrl, key: "url")
        
        return dictionary.copy() as! NSDictionary
    }
}

extension BitBucketStatus.BitBucketState {
    
    static func fromBuildState(state: BuildState) -> BitBucketStatus.BitBucketState {
        switch state {
        case .Success, .NoState: return .Success
        case .Pending: return .InProgress
        case .Error, .Failure: return .Failed
        }
    }
    
    func toBuildState() -> BuildState {
        switch self {
        case .Success: return .Success
        case .InProgress: return .Pending
        case .Failed: return .Failure
        }
    }
}
