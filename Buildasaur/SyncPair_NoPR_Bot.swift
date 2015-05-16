//
//  SyncPair_NoPR_Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer

class SyncPair_NoPR_Bot: SyncPair {
    
    let bot: Bot
    
    init(bot: Bot) {
        self.bot = bot
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //delete the bot
        
        completion(success: true, error: nil)
    }
    
    override func syncPairName() -> String {
        return "No PR + Bot"
    }
}
