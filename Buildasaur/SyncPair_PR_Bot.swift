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
    
    public struct Actions {
        let integrationsToCancel: [Integration]?
        let githubStatusToSet: HDGitHubXCBotSyncer.GitHubStatusAndComment?
        let startNewIntegration: Bool?
    }
    
    let pr: PullRequest
    let bot: Bot
    
    init(pr: PullRequest, bot: Bot) {
        self.pr = pr
        self.bot = bot
        super.init()
    }
    
    override func sync(completion: Completion) {
        
        //sync the PR with the Bot
        self.syncPRWithBot(completion)
    }
    
    override func syncPairName() -> String {
        return "PR (\(self.pr.number):\(self.pr.head.ref)) + Bot (\(self.bot.name))"
    }
    
    //MARK: Performing Actions
    
    private func performActions(actions: Actions, completion: Completion) {
        
        let group = dispatch_group_create()
        var lastGroupError: NSError?
        
        if let integrationsToCancel = actions.integrationsToCancel {
            
            dispatch_group_enter(group)
            self.syncer.cancelIntegrations(integrationsToCancel, completion: { () -> () in
                dispatch_group_leave(group)
            })
        }
        
        if let newStatus = actions.githubStatusToSet {
            
            dispatch_group_enter(group)
            self.syncer.updatePRStatusIfNecessary(newStatus, prNumber: self.pr.number, completion: { (error) -> () in
                if let error = error {
                    lastGroupError = error
                }
                dispatch_group_leave(group)
            })
        }
        
        if let startNewIntegration = actions.startNewIntegration where startNewIntegration {
            
            dispatch_group_enter(group)
            let bot = self.bot
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
    
    //MARK: Internal
    
    private func syncPRWithBot(completion: Completion) {
        
        let syncer = self.syncer
        let pr = self.pr
        let bot = self.bot
        
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
                completion(error: e)
                return
            }
            
            if let integrations = integrations {
                
                //first check whether the bot is even enabled
                SyncPair_PR_Bot.isBotEnabled(syncer, pr: pr, integrations: integrations, completion: { (isEnabled, error) -> () in
                    
                    if let error = error {
                        completion(error: error)
                        return
                    }
                    
                    if isEnabled {
                        
                        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(
                            syncer: syncer,
                            pr: pr,
                            bot: bot,
                            integrations: integrations)
                        self.performActions(actions, completion: completion)
                        
                    } else {
                        
                        //not enabled, make sure the PR reflects that and the instructions are clear
                        Log.verbose("Bot \(bot.name) is not yet enabled, ignoring...")
                        
                        let status = syncer.createStatusFromState(.Pending, description: "Waiting for \"lttm\" to start testing")
                        let notYetEnabled: HDGitHubXCBotSyncer.GitHubStatusAndComment = (status: status, comment: nil)
                        syncer.updatePRStatusIfNecessary(notYetEnabled, prNumber: pr.number, completion: completion)
                    }
                })
            } else {
                let e = Error.withInfo("Getting integrations", internalError: Error.withInfo("Nil integrations even after returning nil error!"))
                completion(error: e)
            }
        })
    }
    
    private class func isBotEnabled(
        syncer: HDGitHubXCBotSyncer,
        pr: PullRequest,
        integrations: [Integration],
        completion: (isEnabled: Bool, error: NSError?) -> ()
        ) {
        
        //bot is enabled if (there are any integrations) OR (there is a recent comment with a keyword to enable the bot in the pull request's conversation)
        //which means that there are two ways of enabling a bot.
        //a) manually start an integration through Xcode, API call or in Builda's GUI (TBB)
        //b) (optional) comment an agreed keyword in the Pull Request, e.g. "lttm" - 'looks testable to me' is a frequent one
        
        if integrations.count > 0 || !syncer.waitForLttm {
            completion(isEnabled: true, error: nil)
            return
        }
        
        let keyword = ["lttm"]
        
        if let repoName = syncer.repoName() {
            
            syncer.github.findMatchingCommentInIssue(keyword, issue: pr.number, repo: repoName) {
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
    
    public class func syncPRWithBotIntegrations(
        #syncer: HDGitHubXCBotSyncer,
        pr: PullRequest,
        bot: Bot,
        integrations: [Integration]
        ) -> Actions {
            
            var integrationsToCancel: [Integration] = []
            var startNewIntegration: Bool?
            
            let uniqueIntegrations = Set(integrations)
            
            //------------
            // Split integrations into two groups: 1) for this SHA, 2) the rest
            //------------
            
            let headCommit: String = pr.head.sha
            
            //1) for this SHA
            let headCommitIntegrations = uniqueIntegrations.filterSet {
                (integration: Integration) -> Bool in
                
                //if it's not pending, we need to take a look at the blueprint and inspect the SHA.
                if let blueprint = integration.blueprint, let sha = blueprint.commitSHA {
                    return sha == headCommit
                }
                
                //when an integration is Pending, Preparing or Checking out, it doesn't have a blueprint, but it is, by definition, a headCommit
                //integration (because it will check out the latest commit on the branch when it starts running)
                if
                    integration.currentStep == .Pending ||
                        integration.currentStep == .Preparing ||
                        integration.currentStep == .Checkout
                {
                    return true
                }
                
                if integration.currentStep == .Completed {
                    
                    if let result = integration.result {
                        
                        //if the result doesn't have a SHA yet and isn't pending - take a look at the result
                        //if it's a checkout-error, assume that it is a malformed SSH key bot, so don't keep
                        //restarting integrations - at least until someone fixes it (by closing the PR and fixing
                        //their SSH keys in Buildasaur so that when the next bot gets created, it does so with the right
                        //SSH keys.
                        if result == .CheckoutError {
                            Log.error("Integration #\(integration.number) finished with a checkout error - please check that your SSH keys setup in Buildasaur are correct! If you need to fix them, please do so and then you need to recreate the bot - e.g. by closing the Pull Request, waiting for a sync (bot will disappear) and then reopening the Pull Request - should do the job!")
                            return true
                        }
                        
                        if result == .Canceled {
                            
                            //another case is when the integration gets doesn't yet have a blueprint AND was cancelled -
                            //we should assume it belongs to the latest commit, because we can't tell otherwise.
                            return true
                        }
                    }
                }
                
                return false
            }
            
            //2) the rest
            let otherCommitIntegrations = uniqueIntegrations.subtract(headCommitIntegrations)
            let noncompletedOtherCommitIntegrations: Set<Integration> = otherCommitIntegrations.filterSet {
                return $0.currentStep != .Completed
            }
            
            //2.1) Ok, now first cancel all unfinished integrations of the non-current commits
            integrationsToCancel += Array(noncompletedOtherCommitIntegrations)
            
            //------------
            // Now we're resolving Integrations for the current commit only
            //------------
            /*
            The resolving logic goes like this now. We have an array of integrations I for the latest commits.
            A. is array empty?
            A1. true -> there are no integrations for this commit. kick one off! we're done.
            A2. false -> keep resolving (all references to "integrations" below mean only integrations of the current commit
            B. take all pending integrations, keep the most recent one, if it's there, cancel all the other ones.
            C. take the running integration, if it's there
            D. take all completed integrations
            
            resolve the status of the PR as follows
            
            E. is there a latest pending integration?
            E1. true -> status is ["Pending": "Waiting on the queue"]. also, if there's a running integration, cancel it.
            E2. false ->
            F. is there a running integration?
            F1. true -> status is ["Pending": "Integration in progress..."]. update status and do nothing else.
            F2. false ->
            G. are there any completed integrations?
            G1. true -> based on the result of the integrations create the PR status
            G2. false -> this shouldn't happen, print a very angry message.
            */
            
            //A. is this array empty?
            if headCommitIntegrations.count == 0 {
                
                //A1. - it's empty, kick off an integration for the latest commit
                startNewIntegration = true
                //nothing else to do
                return Actions(
                    integrationsToCancel: integrationsToCancel,
                    githubStatusToSet: nil,
                    startNewIntegration: startNewIntegration)
                
            }
            
            //A2. not empty, keep resolving
            
            //B. get pending Integrations
            let pending = headCommitIntegrations.filterSet {
                $0.currentStep == .Pending
            }
            
            var latestPendingIntegration: Integration?
            if pending.count > 0 {
                
                //we should cancel all but the most recent one
                //turn the pending set into an array and sort by integration number in ascending order
                var pendingSortedArray: Array<Integration> = Array(pending).sorted({ (integrationA, integrationB) -> Bool in
                    return integrationA.number < integrationB.number
                })
                
                //keep the latest, which will be the last in the array
                //let this one run, it might have been a force rebuild.
                latestPendingIntegration = pendingSortedArray.removeLast()
                
                //however, cancel the rest of the pending integrations
                integrationsToCancel += pendingSortedArray
            }
            
            //Get the running integration, if it's there
            let runningIntegration = headCommitIntegrations.filterSet {
                $0.currentStep != .Completed && $0.currentStep != .Pending
                }.first
            
            //Get all completed integrations for this commit
            let completedIntegrations = headCommitIntegrations.filterSet {
                $0.currentStep == .Completed
            }
            
            //resolve to a status
            let actions = self.resolvePRStatusFromLatestIntegrations(
                syncer: syncer,
                pending: latestPendingIntegration,
                running: runningIntegration,
                completed: completedIntegrations)
            
            //merge in nested actions
            return Actions(
                integrationsToCancel: integrationsToCancel + (actions.integrationsToCancel ?? []),
                githubStatusToSet: actions.githubStatusToSet,
                startNewIntegration: (startNewIntegration ?? false) || (actions.startNewIntegration ?? false)
            )
    }
    
    //MARK: Pure Logic
    
    private class func resolvePRStatusFromLatestIntegrations(
        #syncer: HDGitHubXCBotSyncer,
        pending: Integration?,
        running: Integration?,
        completed: Set<Integration>
        ) -> Actions {
        
        let statusWithComment: HDGitHubXCBotSyncer.GitHubStatusAndComment
        var integrationsToCancel: [Integration] = []
        
        //if there's any pending integration, we're ["Pending" - Waiting in the queue]
        if let pending = pending {
            
            //TODO: show how many builds are ahead in the queue and estimate when it will be
            //started and when finished? (there is an average running time on each bot, it should be easy)
            let status = syncer.createStatusFromState(.Pending, description: "Build waiting in the queue...")
            statusWithComment = (status: status, comment: nil)
            
            //also, cancel the running integration, if it's there any
            if let running = running {
                integrationsToCancel.append(running)
            }
        } else {
            
            //there's no pending integration, it's down to running and completed
            if let running = running {
                
                //there is a running integration.
                //TODO: estimate, based on the average running time of this bot and on the started timestamp, when it will finish. add that to the description.
                let currentStepString = running.currentStep.rawValue
                let status = syncer.createStatusFromState(.Pending, description: "Integration step: \(currentStepString)...")
                statusWithComment = (status: status, comment: nil)
                
            } else {
                
                //there no running integration, we're down to completed integration.
                if completed.count > 0 {
                    
                    //we have some completed integrations
                    statusWithComment = self.resolveStatusFromCompletedIntegrations(syncer: syncer, integrations: completed)
                    
                } else {
                    //this shouldn't happen.
                    Log.error("LOGIC ERROR! This shouldn't happen, there are no completed integrations!")
                    let status = syncer.createStatusFromState(.Error, description: "* UNKNOWN STATE, Builda ERROR *")
                    statusWithComment = (status: status, "Builda error, unknown state!")
                }
            }
        }
        
        return Actions(
            integrationsToCancel: integrationsToCancel,
            githubStatusToSet: statusWithComment,
            startNewIntegration: nil
        )
    }
    
    private class func resolveStatusFromCompletedIntegrations(
        #syncer: HDGitHubXCBotSyncer,
        integrations: Set<Integration>
        ) -> HDGitHubXCBotSyncer.GitHubStatusAndComment {
        
        //get integrations sorted by number
        let sortedDesc = Array(integrations).sorted { $0.number > $1.number }
        
        //if there are any succeeded, it wins - iterating from the end
        if let passingIntegration = sortedDesc.filter({
            (integration: Integration) -> Bool in
            switch integration.result! {
            case Integration.Result.Succeeded, Integration.Result.Warnings, Integration.Result.AnalyzerWarnings:
                return true
            default:
                return false
            }
        }).first {
            
            let baseComment = syncer.baseCommentFromIntegration(passingIntegration)
            let comment: String
            let status = syncer.createStatusFromState(.Success, description: "Build passed!")
            let summary = passingIntegration.buildResultSummary!
            if passingIntegration.result == .Succeeded {
                comment = baseComment + "Perfect build! All \(summary.testsCount) tests passed. :+1:"
            } else if passingIntegration.result == .Warnings {
                comment = baseComment + "All \(summary.testsCount) tests passed, but please fix \(summary.warningCount) warnings."
            } else {
                comment = baseComment + "All \(summary.testsCount) tests passed, but please fix \(summary.analyzerWarningCount) analyzer warnings."
            }
            return (status: status, comment: comment)
        }
        
        //ok, no succeeded, warnings or analyzer warnings, get down to test failures
        if let testFailingIntegration = sortedDesc.filter({
            $0.result! == Integration.Result.TestFailures
        }).first {
            
            let baseComment = syncer.baseCommentFromIntegration(testFailingIntegration)
            let status = syncer.createStatusFromState(.Failure, description: "Build failed tests!")
            let summary = testFailingIntegration.buildResultSummary!
            let comment = baseComment + "Build failed \(summary.testFailureCount) tests out of \(summary.testsCount)"
            return (status: status, comment: comment)
        }
        
        //ok, the build didn't even run then. it either got cancelled or failed
        if let erroredIntegration = sortedDesc.filter({
            $0.result! != Integration.Result.Canceled
        }).first {
            
            let baseComment = syncer.baseCommentFromIntegration(erroredIntegration)
            let errorCount: String
            if let summary = erroredIntegration.buildResultSummary {
                errorCount = "\(summary.errorCount)"
            } else {
                errorCount = "?"
            }
            let status = syncer.createStatusFromState(.Error, description: "Build error!")
            let comment = baseComment + "\(errorCount) build errors: \(erroredIntegration.result!.rawValue)"
            return (status: status, comment: comment)
        }
        
        //cool, not even build error. it must be just canceled ones then.
        if let canceledIntegration = sortedDesc.filter({
            $0.result! == Integration.Result.Canceled
        }).first {
            
            let baseComment = syncer.baseCommentFromIntegration(canceledIntegration)
            let status = syncer.createStatusFromState(.Error, description: "Build canceled!")
            let comment = baseComment + "Build was manually canceled."
            return (status: status, comment: comment)
        }
        
        //hmm no idea, if we got all the way here. just leave it with no state.
        let status = syncer.createStatusFromState(.NoState, description: nil)
        return (status: status, comment: nil)
    }
}

