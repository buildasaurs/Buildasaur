//
//  Branch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

//metadata of a branch
public class Branch : GitHubEntity {
    
    public let name: String
    public let commit: Commit
    
    public required init(json: NSDictionary) {
        
        self.name = json.stringForKey("name")
        self.commit = Commit(json: json.dictionaryForKey("commit"))
        super.init(json: json)
    }
}
