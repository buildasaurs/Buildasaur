//
//  Branch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class Branch : GitHubEntity {
    
    let name: String
    let commit: Commit
    
    required init(json: NSDictionary) {
        
        self.name = json.stringForKey("name")
        self.commit = Commit(json: json.dictionaryForKey("commit"))
        super.init(json: json)
    }
}
