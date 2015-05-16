//
//  SyncPair_PR_NoBot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer

class SyncPair_PR_NoBot: SyncPair {
    
    let pr: PullRequest
    
    init(pr: PullRequest) {
        self.pr = pr
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //create a bot for this PR
        
        completion(error: nil)
    }
    
    override func syncPairName() -> String {
        return "PR + No Bot"
    }
    
}
