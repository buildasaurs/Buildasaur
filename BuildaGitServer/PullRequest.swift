//
//  PullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class PullRequest : Issue {
    
    public let head: PullRequestBranch
    public let base: PullRequestBranch
    
    public required init(json: NSDictionary) {
        
        self.head = PullRequestBranch(json: json.dictionaryForKey("head"))
        self.base = PullRequestBranch(json: json.dictionaryForKey("base"))
        
        super.init(json: json)
    }
}


