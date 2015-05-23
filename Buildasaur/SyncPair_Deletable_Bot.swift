//
//  SyncPair_Deletable_Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer

class SyncPair_Deletable_Bot: SyncPair {
    
    let bot: Bot
    
    init(bot: Bot) {
        self.bot = bot
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //delete the bot
        let syncer = self.syncer
        let bot = self.bot
        
        SyncPair_Deletable_Bot.deleteBot(syncer: syncer, bot: bot, completion: completion)
    }
    
    override func syncPairName() -> String {
        return "Deletable Bot (\(self.bot.name))"
    }
    
    private class func deleteBot(#syncer: HDGitHubXCBotSyncer, bot: Bot, completion: Completion) {
        
        syncer.deleteBot(bot, completion: { () -> () in
            completion(error: nil)
        })
    }
}
