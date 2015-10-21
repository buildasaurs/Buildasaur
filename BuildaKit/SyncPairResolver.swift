//
//  SyncPair_BotLogic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 19/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

public class SyncPairResolver {
    
    public init() {
        //
    }
    
    public func resolveActionsForCommitAndIssueWithBotIntegrations(
        commit: String,
        issue: IssueType?,
        bot: Bot,
        hostname: String,
        integrations: [Integration]) -> SyncPair.Actions {
            
            var integrationsToCancel: [Integration] = []
            let startNewIntegration: Bool = false
            
            //------------
            // Split integrations into two groups: 1) for this SHA, 2) the rest
            //------------
            
            let uniqueIntegrations = Set(integrations)
            
            //1) for this SHA
            let headCommitIntegrations = Set(self.headCommitIntegrationsFromAllIntegrations(commit, allIntegrations: integrations))
            
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
                return SyncPair.Actions(
                    integrationsToCancel: integrationsToCancel,
                    statusToSet: nil,
                    startNewIntegrationBot: bot
                )
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
                var pendingSortedArray: Array<Integration> = Array(pending).sort({ (integrationA, integrationB) -> Bool in
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
            
            let link = { (integration: Integration) -> String? in
                SyncPairResolver.linkToServer(hostname, bot: bot, integration: integration)
            }
            
            //resolve to a status
            let actions = self.resolveCommitStatusFromLatestIntegrations(
                commit,
                issue: issue,
                pending: latestPendingIntegration,
                running: runningIntegration,
                link: link,
                completed: completedIntegrations)
            
            //merge in nested actions
            return SyncPair.Actions(
                integrationsToCancel: integrationsToCancel + (actions.integrationsToCancel ?? []),
                statusToSet: actions.statusToSet,
                startNewIntegrationBot: actions.startNewIntegrationBot ?? (startNewIntegration ? bot : nil)
            )
    }
    
    func headCommitIntegrationsFromAllIntegrations(headCommit: String, allIntegrations: [Integration]) -> [Integration] {
        
        let uniqueIntegrations = Set(allIntegrations)
        
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
        
        let sortedHeadCommitIntegrations = Array(headCommitIntegrations).sort {
            (a: Integration, b: Integration) -> Bool in
            return a.number > b.number
        }
        return sortedHeadCommitIntegrations
    }
    
    class func linkToServer(hostname: String, bot: Bot, integration: Integration) -> String {
        
        //unfortunately, since github doesn't allow non-https links anywhere, we
        //must proxy through Satellite (https://github.com/czechboy0/satellite)
        //all it does is it redirects to the desired xcbot://... url, which in
        //turn opens Xcode on the integration page. all good!
        
//        let link = "xcbot://\(hostname)/botID/\(bot.id)/integrationID/\(integration.id)"
        let link = "https://stlt.herokuapp.com/v1/xcs_deeplink/\(hostname)/\(bot.id)/\(integration.id)"
        return link
    }
    
    func resolveCommitStatusFromLatestIntegrations(
        commit: String,
        issue: IssueType?,
        pending: Integration?,
        running: Integration?,
        link: (Integration) -> String?,
        completed: Set<Integration>) -> SyncPair.Actions {
            
            let statusWithComment: StatusAndComment
            var integrationsToCancel: [Integration] = []
            
            //if there's any pending integration, we're ["Pending" - Waiting in the queue]
            if let pending = pending {
                
                //TODO: show how many builds are ahead in the queue and estimate when it will be
                //started and when finished? (there is an average running time on each bot, it should be easy)
                let status = HDGitHubXCBotSyncer.createStatusFromState(.Pending, description: "Build waiting in the queue...", targetUrl: link(pending))
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
                    let status = HDGitHubXCBotSyncer.createStatusFromState(.Pending, description: "Integration step: \(currentStepString)...", targetUrl: link(running))
                    statusWithComment = (status: status, comment: nil)
                    
                } else {
                    
                    //there no running integration, we're down to completed integration.
                    if completed.count > 0 {
                        
                        //we have some completed integrations
                        statusWithComment = self.resolveStatusFromCompletedIntegrations(completed, link: link)
                        
                    } else {
                        //this shouldn't happen.
                        Log.error("LOGIC ERROR! This shouldn't happen, there are no completed integrations!")
                        let status = HDGitHubXCBotSyncer.createStatusFromState(.Error, description: "* UNKNOWN STATE, Builda ERROR *", targetUrl: nil)
                        statusWithComment = (status: status, "Builda error, unknown state!")
                    }
                }
            }
            
            return SyncPair.Actions(
                integrationsToCancel: integrationsToCancel,
                statusToSet: (status: statusWithComment, commit: commit, issue: issue),
                startNewIntegrationBot: nil
            )
    }
    
    func resolveStatusFromCompletedIntegrations(
        integrations: Set<Integration>,
        link: (Integration) -> String?
        ) -> StatusAndComment {
            
            //get integrations sorted by number
            let sortedDesc = Array(integrations).sort { $0.number > $1.number }
            let summary = SummaryBuilder()
            summary.linkBuilder = link
            
            //if there are any succeeded, it wins - iterating from the end
            if let passingIntegration = sortedDesc.filter({
                (integration: Integration) -> Bool in
                switch integration.result! {
                    
                case .Succeeded, .Warnings, .AnalyzerWarnings:
                    return true
                default:
                    return false
                }
            }).first {
                
                return summary.buildPassing(passingIntegration)
            }
            
            //ok, no succeeded, warnings or analyzer warnings, get down to test failures
            if let testFailingIntegration = sortedDesc.filter({
                $0.result! == .TestFailures
            }).first {
                
                return summary.buildFailingTests(testFailingIntegration)
            }
            
            //ok, the build didn't even run then. it either got cancelled or failed
            if let errorredIntegration = sortedDesc.filter({
                $0.result! != .Canceled
            }).first {
                
                return summary.buildErrorredIntegration(errorredIntegration)
            }
            
            //cool, not even build error. it must be just canceled ones then.
            if let canceledIntegration = sortedDesc.filter({
                $0.result! == .Canceled
            }).first {
                
                return summary.buildCanceledIntegration(canceledIntegration)
            }
            
            //hmm no idea, if we got all the way here. just leave it with no state.
            return summary.buildEmptyIntegration()
    }
}
