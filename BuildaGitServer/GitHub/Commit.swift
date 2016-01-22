//
//  Commit.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

//GitHub commit in all its glory, with git commit metadata, plus comments, committer, author and parents info
class Commit : GitHubEntity {
    
    let sha: String

    required init(json: NSDictionary) {
        
        self.sha = json.stringForKey("sha")
        
        super.init(json: json)
    }
}



