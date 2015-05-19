//
//  SyncPairExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 19/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

extension SyncPair {
    
    public struct Actions {
        public let integrationsToCancel: [Integration]?
        public let githubStatusToSet: (status: HDGitHubXCBotSyncer.GitHubStatusAndComment, pr: PullRequest)?
        public let startNewIntegrationBot: Bot? //if non-nil, starts a new integration on this bot
    }

    func performActions(actions: Actions, completion: Completion) {
        
        let group = dispatch_group_create()
        var lastGroupError: NSError?
        
        if let integrationsToCancel = actions.integrationsToCancel {
            
            dispatch_group_enter(group)
            self.syncer.cancelIntegrations(integrationsToCancel, completion: { () -> () in
                dispatch_group_leave(group)
            })
        }
        
        if let newStatus = actions.githubStatusToSet {
            
            let status = newStatus.status
            let pr = newStatus.pr
            
            dispatch_group_enter(group)
            self.syncer.updatePRStatusIfNecessary(status, prNumber: pr.number, completion: { (error) -> () in
                if let error = error {
                    lastGroupError = error
                }
                dispatch_group_leave(group)
            })
        }
        
        if let startNewIntegrationBot = actions.startNewIntegrationBot {
            
            let bot = startNewIntegrationBot
            
            dispatch_group_enter(group)
            self.syncer.xcodeServer.postIntegration(bot.id, completion: { (integration, error) -> () in
                
                if let integration = integration where error == nil {
                    Log.info("Bot \(bot.name) successfully enqueued Integration #\(integration.number)")
                } else {
                    let e = Error.withInfo("Bot \(bot.name) failed to enqueue an integration", internalError: error)
                    lastGroupError = e
                }
                
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), {
            completion(error: lastGroupError)
        })
    }

}
