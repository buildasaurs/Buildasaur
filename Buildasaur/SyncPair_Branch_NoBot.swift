//
//  SyncPair_Branch_NoBot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 20/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer

class SyncPair_Branch_NoBot: SyncPair {
    
    let branch: Branch
    let repo: Repo
    
    init(branch: Branch, repo: Repo) {
        self.branch = branch
        self.repo = repo
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //create a bot for this branch
        let syncer = self.syncer
        let branch = self.branch
        let repo = self.repo
        
        SyncPair_Branch_NoBot.createBotForBranch(syncer: syncer, branch: branch, repo: repo, completion: completion)
    }
    
    override func syncPairName() -> String {
        return "Branch (\(self.branch.name)) + No Bot"
    }
    
    //MARK: Internal
    
    private class func createBotForBranch(syncer syncer: HDGitHubXCBotSyncer, branch: Branch, repo: Repo, completion: Completion) {
        
        syncer.createBotFromBranch(branch, repo: repo, completion: { () -> () in
            completion(error: nil)
        })
    }
}
