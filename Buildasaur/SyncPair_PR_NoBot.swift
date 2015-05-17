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
        let syncer = self.syncer
        let pr = self.pr
        
        SyncPair_PR_NoBot.createBotForPR(syncer: syncer, pr: pr, completion: completion)
    }
    
    override func syncPairName() -> String {
        return "PR (\(self.pr.head.ref)) + No Bot"
    }
    
    //MARK: Internal
    
    private class func createBotForPR(#syncer: HDGitHubXCBotSyncer, pr: PullRequest, completion: Completion) {
        
        syncer.createBotFromPR(pr, completion: { () -> () in
            completion(error: nil)
        })
    }
    
}
