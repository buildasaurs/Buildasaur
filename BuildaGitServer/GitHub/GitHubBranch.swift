//
//  GitHubBranch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubBranch : GitHubEntity {
    
    let name: String
    let commit: GitHubCommit
    
    required init(json: NSDictionary) {
        
        self.name = json.stringForKey("name")
        self.commit = GitHubCommit(json: json.dictionaryForKey("commit"))
        super.init(json: json)
    }
}

extension GitHubBranch: BranchType {
    
    //name (see above)
    
    var commitSHA: String {
        return self.commit.sha
    }
    
}
