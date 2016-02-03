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
    
    let branch: BranchType
    let repo: RepoType
    
    init(branch: BranchType, repo: RepoType) {
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
    
    private class func createBotForBranch(syncer syncer: StandardSyncer, branch: BranchType, repo: RepoType, completion: Completion) {
        
        syncer.createBotFromBranch(branch, repo: repo, completion: { () -> () in
            completion(error: nil)
        })
    }
}
