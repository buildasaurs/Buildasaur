//
//  BotNaming.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer

class BotNaming {
    
    class func isBuildaBot(bot: Bot) -> Bool {
        return bot.name.hasPrefix(self.prefixForBuildaBot())
    }
    
    class func isBuildaBotBelongingToRepoWithName(bot: Bot, repoName: String) -> Bool {
        return bot.name.hasPrefix(self.prefixForBuildaBotInRepoWithName(repoName))
    }
    
    class func nameForBotWithPR(pr: PullRequest, repoName: String) -> String {
        return "\(self.prefixForBuildaBotInRepoWithName(repoName)) PR #\(pr.number)"
    }
    
    class func prefixForBuildaBotInRepoWithName(repoName: String) -> String {
        return "\(self.prefixForBuildaBot()) [\(repoName)]"
    }
    
    class func prefixForBuildaBot() -> String {
        return "BuildaBot"
    }
}
