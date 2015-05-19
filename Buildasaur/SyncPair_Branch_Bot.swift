//
//  SyncPair_Branch_Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 19/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

public class SyncPair_Branch_Bot: SyncPair {
    
    let branch: Branch
    let bot: Bot
    
    public init(branch: Branch, bot: Bot) {
        self.branch = branch
        self.bot = bot
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //sync the branch with the bot
    }
    
    override func syncPairName() -> String {
        return "Branch (\(self.branch.name)) + Bot (\(self.bot.name))"
    }
}
