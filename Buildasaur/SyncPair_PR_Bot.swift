//
//  SyncPair_PR_Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

public class SyncPair_PR_Bot: SyncPair {
    
    let pr: PullRequest
    let bot: Bot
    let resolver: SyncPairPRResolver
    
    public init(pr: PullRequest, bot: Bot, resolver: SyncPairPRResolver) {
        self.pr = pr
        self.bot = bot
        self.resolver = resolver
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //sync the PR with the Bot
        self.syncPRWithBot(completion)
    }
    
    override func syncPairName() -> String {
        return "PR (\(self.pr.number):\(self.pr.head.ref)) + Bot (\(self.bot.name))"
    }
    
    //MARK: Internal
    
    private func syncPRWithBot(completion: Completion) {
        
        let syncer = self.syncer
        let bot = self.bot
        let pr = self.pr
        let headCommit = pr.head.sha
        let issue = pr

        self.getIntegrations(bot, completion: { (integrations, error) -> () in
            
            if let error = error {
                completion(error: error)
                return
            }
            
            //first check whether the bot is even enabled
            self.isBotEnabled(integrations: integrations, completion: { (isEnabled, error) -> () in
                
                if let error = error {
                    completion(error: error)
                    return
                }
                
                if isEnabled {
                    
                    let actions = self.resolver.resolveActionsForCommitAndIssueWithBotIntegrations(
                        headCommit,
                        issue: issue,
                        bot: bot,
                        integrations: integrations)
                    self.performActions(actions, completion: completion)
                    
                } else {
                    
                    //not enabled, make sure the PR reflects that and the instructions are clear
                    Log.verbose("Bot \(bot.name) is not yet enabled, ignoring...")
                    
                    let status = HDGitHubXCBotSyncer.createStatusFromState(.Pending, description: "Waiting for \"lttm\" to start testing")
                    let notYetEnabled: HDGitHubXCBotSyncer.GitHubStatusAndComment = (status: status, comment: nil)
                    syncer.updateCommitStatusIfNecessary(notYetEnabled, commit: headCommit, issue: pr, completion: completion)
                }
            })
        })
    }
    
    private func isBotEnabled(#integrations: [Integration], completion: (isEnabled: Bool, error: NSError?) -> ()) {
        
        //bot is enabled if (there are any integrations) OR (there is a recent comment with a keyword to enable the bot in the pull request's conversation)
        //which means that there are two ways of enabling a bot.
        //a) manually start an integration through Xcode, API call or in Builda's GUI (TBB)
        //b) (optional) comment an agreed keyword in the Pull Request, e.g. "lttm" - 'looks testable to me' is a frequent one
        
        if integrations.count > 0 || !self.syncer.waitForLttm {
            completion(isEnabled: true, error: nil)
            return
        }
        
        let keyword = ["lttm"]
        
        if let repoName = syncer.repoName() {
            
            self.syncer.github.findMatchingCommentInIssue(keyword, issue: self.pr.number, repo: repoName) {
                (foundComments, error) -> () in
                
                if error != nil {
                    let e = Error.withInfo("Fetching comments", internalError: error)
                    completion(isEnabled: false, error: e)
                    return
                }
                
                if let foundComments = foundComments {
                    completion(isEnabled: foundComments.count > 0, error: nil)
                } else {
                    completion(isEnabled: false, error: nil)
                }
            }
            
        } else {
            completion(isEnabled: false, error: Error.withInfo("No repo name, cannot find the GitHub repo!"))
        }
    }
}

