//
//  SyncPairExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 19/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

extension SyncPair {
    
    public struct Actions {
        public let integrationsToCancel: [Integration]?
        public let githubStatusToSet: (status: HDGitHubXCBotSyncer.GitHubStatusAndComment, commit: String, issue: Issue?)?
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
            let commit = newStatus.commit
            let issue = newStatus.issue
            
            dispatch_group_enter(group)
            self.syncer.updateCommitStatusIfNecessary(status, commit: commit, issue: issue, completion: { (error) -> () in
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
    
    //MARK: Utility functions
    
    func getIntegrations(bot: Bot, completion: (integrations: [Integration], error: NSError?) -> ()) {
        
        let syncer = self.syncer
        
        /*
        TODO: we should establish some reliable and reasonable plan for how many integrations to fetch.
        currently it's always 20, but some setups might have a crazy workflow with very frequent commits
        on active bots etc.
        */
        let query = [
            "last": "20"
        ]
        syncer.xcodeServer.getIntegrations(bot.id, query: query, completion: { (integrations, error) -> () in
            
            if let error = error {
                let e = Error.withInfo("Bot \(bot.name) failed return integrations", internalError: error)
                completion(integrations: [], error: e)
                return
            }
            
            if let integrations = integrations {
                
                completion(integrations: integrations, error: nil)
                
            } else {
                let e = Error.withInfo("Getting integrations", internalError: Error.withInfo("Nil integrations even after returning nil error!"))
                completion(integrations: [], error: e)
            }
        })
    }


}
