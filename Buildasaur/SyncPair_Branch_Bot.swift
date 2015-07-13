//
//  SyncPair_Branch_Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 19/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

public class SyncPair_Branch_Bot: SyncPair {
    
    let branch: Branch
    let bot: Bot
    let resolver: SyncPairBranchResolver
    
    public init(branch: Branch, bot: Bot, resolver: SyncPairBranchResolver) {
        self.branch = branch
        self.bot = bot
        self.resolver = resolver
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //sync the branch with the bot
        self.syncBranchWithBot(completion)
    }
    
    override func syncPairName() -> String {
        return "Branch (\(self.branch.name)) + Bot (\(self.bot.name))"
    }
    
    //MARK: Internal
    
    private func syncBranchWithBot(completion: Completion) {
        
        let bot = self.bot
        let headCommit = self.branch.commit.sha
        let issue: Issue? = nil //TODO: only pull/create if we're failing
        
        self.getIntegrations(bot, completion: { (integrations, error) -> () in
            
            if let error = error {
                completion(error: error)
                return
            }
            
            let actions = self.resolver.resolveActionsForCommitAndIssueWithBotIntegrations(
                headCommit,
                issue: issue,
                bot: bot,
                integrations: integrations)
            
            //in case of branches, we also (optionally) want to add functionality for creating an issue if the branch starts failing and updating with comments the same way we do with PRs.
            //also, when the build is finally successful on the branch, the issue will be automatically closed.
            //TODO: add this functionality here and add it as another action available from a sync pair
            
            self.performActions(actions, completion: completion)
        })
    }
}
