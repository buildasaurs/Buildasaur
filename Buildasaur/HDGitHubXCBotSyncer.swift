//
//  HDGitHubXCBotSyncer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

public class HDGitHubXCBotSyncer : Syncer {
    
    let github: GitHubServer!
    let xcodeServer: XcodeServer!
    let localSource: LocalSource!
    
    typealias GitHubStatusAndComment = (status: Status, comment: String?)
    
    init(integrationServer: XcodeServer, sourceServer: GitHubServer, localSource: LocalSource, syncInterval: NSTimeInterval) {
        
        self.github = sourceServer
        self.xcodeServer = integrationServer
        self.localSource = localSource
        super.init(syncInterval: syncInterval)
    }
    
    init?(json: NSDictionary, storageManager: StorageManager) {
        
        if
            let syncInterval = json.optionalDoubleForKey("sync_interval"),
            let projectPath = json.optionalStringForKey("project_path"),
            let serverHost = json.optionalStringForKey("server_host"),
            let project = storageManager.projects.filter({ $0.url.absoluteString == projectPath }).first,
            let serverConfig = storageManager.servers.filter({ $0.host == serverHost }).first
        {
            self.localSource = project
            self.github = GitHubFactory.server(project.githubToken)
            self.xcodeServer = XcodeServerFactory.server(serverConfig)
            super.init(syncInterval: syncInterval)
            
        } else {
            
            self.github = nil
            self.xcodeServer = nil
            self.localSource = nil
            super.init(syncInterval: 0)
            return nil
        }
    }
    
    func jsonify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        dict["sync_interval"] = self.syncInterval
        dict["project_path"] = self.localSource.url.absoluteString
        dict["server_host"] = self.xcodeServer.config.host
        return dict
    }
    
    private func repoName() -> String? {
        return self.localSource.githubRepoName()
    }
    
    public override func sync(completion: () -> ()) {
        
        if let repoName = self.repoName() {
            
            //pull PRs from github
            self.github.getOpenPullRequests(repoName, completion: { (prs, error) -> () in
                
                if error != nil {
                    //whoops, no more syncing for now
                    self.notifyError(error, context: "Fetching PRs")
                    completion()
                    return
                }
                
                if let prs = prs {
                    
                    self.reports["All Pull Requests"] = "\(prs.count)"
                    
                    //we have PRs, now fetch bots
                    self.xcodeServer.getBots({ (bots, error) -> () in
                        
                        if let error = error {
                            //whoops, no more syncing for now
                            self.notifyError(error, context: "Fetching Bots")
                            completion()
                            return
                        }
                        
                        if let bots = bots {
                            
                            self.reports["All Bots"] = "\(bots.count)"
                            
                            self.resolvePRsAndBots(repoName: repoName, prs: prs, bots: bots, completion: {
                                
                                if let rateLimitInfo = self.github.latestRateLimitInfo {
                                    
                                    let report = rateLimitInfo.getReport()
                                    self.reports["GitHub Rate Limit"] = report
                                    Log.info("GitHub Rate Limit: \(report)")
                                }
                                
                                completion()
                            })
                        } else {
                            self.notifyError(Errors.errorWithInfo("Nil bots even when error was nil"), context: "Fetching Bots")
                            completion()
                        }
                    })
                    
                } else {
                    self.notifyError(Errors.errorWithInfo("PRs are nil and error is nil"), context: "Fetching PRs")
                    completion()
                }
            })
            
        } else {
            self.notifyError(nil, context: "No repo name for GitHub found in URL")
            completion()
        }
    }
    
    private func resolvePRsAndBots(#repoName: String, prs: [PullRequest], bots: [Bot], completion: () -> ()) {
        
        let prsDescription = prs.map({ "\n\tPR \($0.number): \($0.title) [\($0.head.ref) -> \($0.base.ref))]" }) + ["\n"]
        let botsDescription = bots.map({ "\n\t\($0.name)" }) + ["\n"]
        
        Log.verbose("Resolving prs:\n\(prsDescription) \nand bots:\n\(botsDescription)")
        
        if let repoName = self.repoName() {
            
            //first filter only builda's bots, don't manipulate manually created bots
            //also filter only bots that belong to this project
            let buildaBots = bots.filter { self.isBuildaBotBelongingToRepoWithName($0, repoName: repoName) }
            
            //create a map of name -> bot for fast manipulation
            var mappedBots = [String: Bot]()
            for bot in buildaBots {
                mappedBots[bot.name] = bot
            }
            
            //keep track of the ones that have a PR
            var toSync: [(pr: PullRequest, bot: Bot)] = []
            var toCreate: [PullRequest] = []
            for pr in prs {
                
                let botName = self.nameForBotWithPR(pr, repoName: repoName)
                
                if let bot = mappedBots[botName] {
                    //we found a corresponding bot to this PR, add to toSync
                    toSync.append((pr: pr, bot: bot))
                    
                    //and remove from bots mappedBots, because we handled it
                    mappedBots.removeValueForKey(botName)
                } else {
                    //no bot found for this PR, we'll have to create one
                    toCreate.append(pr)
                }
            }
            
            //bots that we haven't found a corresponding PR for we delete
            let toDelete = mappedBots.values.array
            
            //apply changes
            self.applyResolvedChanges(toSync: toSync, toCreate: toCreate, toDelete: toDelete, completion: completion)
        } else {
            self.notifyError(Errors.errorWithInfo("Nil repo name"), context: "Resolving PRs and Bots")
            completion()
        }
    }
    
    private func applyResolvedChanges(#toSync: [(pr: PullRequest, bot: Bot)], toCreate: [PullRequest], toDelete: [Bot], completion: () -> ()) {
        
        let group = dispatch_group_create()

        //first delete outdated bots
        dispatch_group_enter(group)
        self.deleteBots(toDelete, completion: { () -> () in
            dispatch_group_leave(group)
        })
        
        //create new bots with prs
        dispatch_group_enter(group)
        self.createBotsFromPRs(toCreate, completion: { () -> () in
            dispatch_group_leave(group)
        })
        
        //and sync PR + Bot pairs
        dispatch_group_enter(group)
        self.syncPRBotPairs(toSync, completion: { () -> () in
            dispatch_group_leave(group)
        })
        
        //when both, finish this method as well
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            
            if toCreate.count > 0 {
                self.reports["Created bots"] = "\(toCreate.count)"
            }
            if toDelete.count > 0 {
                self.reports["Deleted bots"] = "\(toDelete.count)"
            }
            if toSync.count > 0 {
                self.reports["Synced bots"] = "\(toSync.count)"
            }

            completion()
        }
    }
    
    private func syncPRBotPairs(pairs: [(pr: PullRequest, bot: Bot)], completion: () -> ()) {
        
        pairs.mapVoidAsync({ (pair, itemCompletion) -> () in
            self.tryToSyncPRWithBot(pair.pr, bot: pair.bot, completion: { () -> () in
                Log.verbose("Synced up PR #\(pair.pr.number) with bot \(pair.bot.name)")
                itemCompletion()
            })
        }, completion: completion)
    }
    
    private func isBotEnabled(pr: PullRequest, integrations: [Integration], completion: (isEnabled: Bool) -> ()) {
        
        //bot is enabled if (there are any integrations) OR (there is a recent comment with a keyword to enable the bot in the pull request's conversation)
        //which means that there are two ways of enabling a bot. 
        //a) manually start an integration through Xcode, API call or in Builda's GUI (TBB)
        //b) comment an agreed keyword in the Pull Request, e.g. "lttm" - 'looks testable to me' is a frequent one
        
        if integrations.count > 0 {
            completion(isEnabled: true)
            return
        }
        
        let keyword = ["lttm"]
        
        if let repoName = self.repoName() {

            self.github.findMatchingCommentInIssue(keyword, issue: pr.number, repo: repoName) {
                (foundComments, error) -> () in
                
                if error != nil {
                    self.notifyError(error, context: "Fetching comments")
                    completion(isEnabled: false)
                    return
                }
                
                if let foundComments = foundComments {
                    completion(isEnabled: foundComments.count > 0)
                } else {
                    completion(isEnabled: false)
                }
            }

        } else {
            Log.error("No repo name, cannot find the GitHub repo!")
            completion(isEnabled: false)
        }
    }
    
    private func tryToSyncPRWithBot(pr: PullRequest, bot: Bot, completion: () -> ()) {
        
        /*
        TODO: we should establish some reliable and reasonable plan for how many integrations to fetch.
        currently it's always 20, but some setups might have a crazy workflow with very frequent commits
        on active bots etc.
        */
        let query = [
            "last": "20"
        ]
        self.xcodeServer.getIntegrations(bot.id, query: query, completion: { (integrations, error) -> () in
            
            if let error = error {
                self.notifyError(error, context: "Bot \(bot.name) failed return integrations")
                completion()
                return
            }
            
            if let integrations = integrations {
                
                //first check whether the bot is even enabled
                self.isBotEnabled(pr, integrations: integrations, completion: { (isEnabled) -> () in
                    
                    if isEnabled {
                        
                        self.syncPRWithBotIntegrations(pr, bot: bot, integrations: integrations, completion: completion)
                        
                    } else {
                        
                        //not enabled, make sure the PR reflects that and the instructions are clear
                        Log.verbose("Bot \(bot.name) is not yet enabled, ignoring...")
                        
                        let status = self.createStatusFromState(.Pending, description: "Waiting for \"lttm\" to start testing")
                        let notYetEnabled = GitHubStatusAndComment(status: status, comment: nil)
                        self.updatePRStatusIfNecessary(notYetEnabled, prNumber: pr.number, completion: completion)
                    }
                })
            } else {
                self.notifyError(Errors.errorWithInfo("Nil integrations even after returning nil error!"), context: "Getting integrations")
            }
        })
    }
    
    private func updatePRStatusIfNecessary(newStatus: GitHubStatusAndComment, prNumber: Int, completion: () -> ()) {
        
        let repoName = self.repoName()!
        
        self.github.getPullRequest(prNumber, repo: repoName) { (pr, error) -> () in
            
            if error != nil {
                self.notifyError(error, context: "PR \(prNumber) failed to return data")
                completion()
                return
            }
            
            if let pr = pr {

                let latestCommit = pr.head.sha
                
                self.github.getStatusOfCommit(latestCommit, repo: repoName, completion: { (status, error) -> () in
                    
                    if error != nil {
                        self.notifyError(error, context: "PR \(prNumber) failed to return status")
                        completion()
                        return
                    }
                    
                    if status == nil || newStatus.status != status! {
                        
                        self.postStatusWithComment(newStatus, commit: latestCommit, repo: repoName, pr: pr, completion: completion)
                        
                    } else {
                        completion()
                    }
                })

            } else {
                self.notifyError(Errors.errorWithInfo("PR is nil and error is nil"), context: "Fetching a PR")
                completion()
            }
        }
    }
    
    private func syncPRWithBotIntegrations(pr: PullRequest, bot: Bot, integrations: [Integration], completion: () -> ()) {

        let group = dispatch_group_create()
        
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
            
            //if the result doesn't have a SHA yet and isn't pending - take a look at the result
            //if it's a checkout-error, assume that it is a malformed SSH key bot, so don't keep
            //restarting integrations - at least until someone fixes it (by closing the PR and fixing
            //their SSH keys in Buildasaur so that when the next bot gets created, it does so with the right
            //SSH keys.
            if integration.currentStep == .Completed {
                if let result = integration.result {
                    if result == .CheckoutError {
                        Log.error("Integration #\(integration.number) finished with a checkout error - please check that your SSH keys setup in Buildasaur are correct! If you need to fix them, please do so and then you need to recreate the bot - e.g. by closing the Pull Request, waiting for a sync (bot will disappear) and then reopening the Pull Request - should do the job!")
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
        dispatch_group_enter(group)
        self.cancelIntegrations(Array(noncompletedOtherCommitIntegrations), completion: { () -> () in
            dispatch_group_leave(group)
        })
        
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
            dispatch_group_enter(group)
            self.xcodeServer.postIntegration(bot.id, completion: { (integration, error) -> () in
                
                if let integration = integration where error == nil {
                    Log.info("Bot \(bot.name) successfully enqueued Integration #\(integration.number)")
                } else {
                    self.notifyError(error, context: "Bot \(bot.name) failed to enqueue an integration")
                }
                
                dispatch_group_leave(group)
            })
            //nothing else to do
            
        } else {
            
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
                dispatch_group_enter(group)
                self.cancelIntegrations(pendingSortedArray) {
                    dispatch_group_leave(group)
                }
            }
            
            //Get the running integration, if it's there
            let runningIntegration = headCommitIntegrations.filterSet {
                $0.currentStep != .Completed && $0.currentStep != .Pending
            }.first
            
            //Get all completed integrations for this commit
            let completedIntegrations = headCommitIntegrations.filterSet {
                $0.currentStep == .Completed
            }
            
            //resolve
            dispatch_group_enter(group)
            self.resolvePRStatusFromLatestIntegrations(pending: latestPendingIntegration, running: runningIntegration, completed: completedIntegrations, completion: { (statusWithComment) -> () in
                
                //we now have the status and an optional comment to add.
                //in order to know what to do, we need to fetch the current status of this commit first.
                let repoName = self.repoName()!
                self.github.getStatusOfCommit(headCommit, repo: repoName, completion: { (status, error) -> () in
                  
                    if error != nil {
                        self.notifyError(error, context: "Failed to fetch status of commit \(headCommit) in repo \(repoName)")
                        dispatch_group_leave(group)
                        return
                    }
                    
                    let updateStatus: Bool
                    if let currentStatus = status {
                        //we have the current status!
                        updateStatus = (statusWithComment.status != currentStatus)
                    } else {
                        //doesn't have a status yet, update
                        updateStatus = true
                    }
                    
                    if updateStatus {
                        
                        let oldStatus = status?.description ?? "[no status]"
                        let newStatus = statusWithComment
                        let comment = newStatus.comment ?? "[no comment]"
                        Log.info("Updating status of commit \(headCommit) in PR #\(pr.number) from \(oldStatus) to \(newStatus), will add comment \(comment)")
                        
                        //we need to update status
                        self.postStatusWithComment(statusWithComment, commit: headCommit, repo: repoName, pr: pr, completion: { () -> () in
                            dispatch_group_leave(group)
                        })
                        
                    } else {
                        //everything is how it's supposed to be
                        dispatch_group_leave(group)
                    }
                })
            })
            
        }
        
        //when all actions finished, complete
        dispatch_group_notify(group, dispatch_get_main_queue(), completion)
    }
    
    private func postStatusWithComment(statusWithComment: GitHubStatusAndComment, commit: String, repo: String, pr: PullRequest, completion: () -> ()) {
        
        self.github.postStatusOfCommit(statusWithComment.status, sha: commit, repo: repo) { (status, error) -> () in
            
            if error != nil {
                self.notifyError(error, context: "Failed to post a status on commit \(commit) of repo \(repo)")
                completion()
                return
            }
            
            //optional there can be a comment to be posted as well
            if let comment = statusWithComment.comment {
                
                //we have a comment, post it
                self.github.postCommentOnIssue(comment, issueNumber: pr.number, repo: repo, completion: { (comment, error) -> () in
                    
                    if error != nil {
                        self.notifyError(error, context: "Failed to post a comment \"\(comment)\" on PR \(pr.number) of repo \(repo)")
                    }
                    completion()
                })
                
            } else {
                completion()
            }
        }
    }
    
    private func resolvePRStatusFromLatestIntegrations(#pending: Integration?, running: Integration?, completed: Set<Integration>, completion: (GitHubStatusAndComment) -> ()) {
        
        let group = dispatch_group_create()
        let statusWithComment: GitHubStatusAndComment
        
        //if there's any pending integration, we're ["Pending" - Waiting in the queue]
        if let pending = pending {
            
            //TODO: show how many builds are ahead in the queue and estimate when it will be
            //started and when finished? (there is an average running time on each bot, we it should be easy)
            let status = self.createStatusFromState(.Pending, description: "Build waiting in the queue...")
            statusWithComment = (status: status, comment: nil)
            
            //also, cancel the running integration, if it's there
            if let running = running {
                dispatch_group_enter(group)
                self.cancelIntegrations([running], completion: { () -> () in
                    dispatch_group_leave(group)
                })
            }
        } else {
            
            //there's no pending integration, it's down to running and completed possibly being there
            if let running = running {
                
                //there is a running integration. 
                //TODO: estimate, based on the average running time of this bot and on the started timestamp, when it will finish. add that to the description.
                let currentStepString = running.currentStep.rawValue
                let status = self.createStatusFromState(.Pending, description: "Integration step: \(currentStepString)...")
                statusWithComment = (status: status, comment: nil)

            } else {
                
                //there no running integration, we're down to completed integration.
                if completed.count > 0 {
                    
                    //we have some completed integrations
                    statusWithComment = self.resolveStatusFromCompletedIntegrations(completed)

                } else {
                    //this shouldn't happen.
                    Log.error("LOGIC ERROR! This shouldn't happen, there are no completed integrations!")
                    let status = self.createStatusFromState(.Error, description: "* UNKNOWN STATE, Builda ERROR *")
                    statusWithComment = (status: status, "Builda error, unknown state!")
                }
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            completion(statusWithComment)
        }
    }
    
    private func resolveStatusFromCompletedIntegrations(integrations: Set<Integration>) -> GitHubStatusAndComment {
        
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
            
            let baseComment = "Result of integration \(passingIntegration.number)\n"
            let comment: String
            let status = self.createStatusFromState(.Success, description: "Build passed!")
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
            
            let baseComment = "Result of integration \(testFailingIntegration.number)\n"
            let status = self.createStatusFromState(.Failure, description: "Build failed tests!")
            let summary = testFailingIntegration.buildResultSummary!
            let comment = baseComment + "Build failed \(summary.testFailureCount) tests out of \(summary.testsCount)"
            return (status: status, comment: comment)
        }
        
        //ok, the build didn't even run then. it either got cancelled or failed
        if let erroredIntegration = sortedDesc.filter({
            $0.result! != Integration.Result.Canceled
        }).first {
            let baseComment = "Result of integration \(erroredIntegration.number)\n"
            let errorCount: String
            if let summary = erroredIntegration.buildResultSummary {
                errorCount = "\(summary.errorCount)"
            } else {
                errorCount = "?"
            }
            let status = self.createStatusFromState(.Error, description: "Build error!")
            let comment = baseComment + "\(errorCount) build errors: \(erroredIntegration.result!.rawValue)"
            return (status: status, comment: comment)
        }
        
        //cool, not even build error. it must be just canceled ones then.
        if let canceledIntegration = sortedDesc.filter({
            $0.result! == Integration.Result.Canceled
        }).first {
            let baseComment = "Result of integration \(canceledIntegration.number)\n"
            let status = self.createStatusFromState(.Error, description: "Build canceled!")
            let comment = baseComment + "Build was manually canceled."
            return (status: status, comment: comment)
        }
        
        //hmm no idea, if we got all the way here. just leave it with no state.
        let status = self.createStatusFromState(.NoState, description: nil)
        return (status: status, comment: nil)
    }
    
    private func createStatusFromState(state: Status.State, description: String?) -> Status {
        
        //TODO: add useful targetUrl and potentially have multiple contexts to show multiple stats on the PR
        let context = "Buildasaur"
        let newDescription: String?
        if let description = description {
            newDescription = "\(context): \(description)"
        } else {
            newDescription = nil
        }
        return Status(state: state, description: newDescription, targetUrl: nil, context: context)
    }
    
    //probably make these a bit more generic, something like an async reduce which calls completion when all finish
    private func cancelIntegrations(integrations: [Integration], completion: () -> ()) {
        
        integrations.mapVoidAsync({ (integration, itemCompletion) -> () in
            
            self.xcodeServer.cancelIntegration(integration.id, completion: { (success, error) -> () in
                if error != nil {
                    self.notifyError(error, context: "Failed to cancel integration \(integration.number)")
                } else {
                    Log.info("Successfully cancelled integration \(integration.number)")
                }
                itemCompletion()
            })
            
        }, completion: completion)
    }
    
    private func deleteBots(bots: [Bot], completion: () -> ()) {
        
        bots.mapVoidAsync({ (bot, itemCompletion) -> () in
            
            self.xcodeServer.deleteBot(bot.id, revision: bot.rev, completion: { (success, error) -> () in
                
                if error != nil {
                    self.notifyError(error, context: "Failed to delete bot with name \(bot.name)")
                } else {
                    Log.info("Successfully deleted bot \(bot.name)")
                }
                itemCompletion()
            })
            
        }, completion: completion)
    }
    
    private func createBotsFromPRs(prs: [PullRequest], completion: () -> ()) {
        
        prs.mapVoidAsync({ (item, itemCompletion) -> () in
            self.createBotFromPR(item, completion: itemCompletion)
        }, completion: completion)
    }
    
    private func createBotFromPR(pr: PullRequest, completion: () -> ()) {
        
        /*
        synced bots must have a manual schedule, Builda tells the bot to reintegrate in case of a new commit.
        this has the advantage in cases when someone pushes 10 commits. if we were using Xcode Server's "On Commit"
        schedule, it'd schedule 10 integrations, which could take ages. Builda's logic instead only schedules one
        integration for the latest commit's SHA.
        
        even though this is desired behavior in this syncer, technically different syncers can have completely different
        logic. here I'm just explaining why "On Commit" schedule isn't generally a good idea for when managed by Builda.
        */
        let schedule = BotSchedule.manualBotSchedule()
        let botName = self.nameForBotWithPR(pr, repoName: self.repoName()!)
        let template = self.currentBuildTemplate()
        let project = self.localSource
        let xcodeServer = self.xcodeServer
        let branch = pr.head.ref

        XcodeServerSyncerUtils.createBotFromBuildTemplate(botName, template: template, project: self.localSource, branch: branch, scheduleOverride: schedule, xcodeServer: xcodeServer) { (bot, error) -> () in
            
            if error != nil {
                self.notifyError(error, context: "Failed to create bot with name \(botName)")
            }
            completion()
        }
    }
    
    private func currentBuildTemplate() -> BuildTemplate! {
        
        if
            let preferredTemplateId = self.localSource.preferredTemplateId,
            let template = StorageManager.sharedInstance.buildTemplates.filter({ $0.uniqueId == preferredTemplateId }).first {
                return template
        }

        assertionFailure("Couldn't get the current build template, this syncer should NOT be running!")
        return nil
    }
    
    private func isBuildaBot(bot: Bot) -> Bool {
        return bot.name.hasPrefix(self.prefixForBuildaBot())
    }
    
    private func isBuildaBotBelongingToRepoWithName(bot: Bot, repoName: String) -> Bool {
        return bot.name.hasPrefix(self.prefixForBuildaBotInRepoWithName(repoName))
    }
    
    private func nameForBotWithPR(pr: PullRequest, repoName: String) -> String {
        return "\(self.prefixForBuildaBotInRepoWithName(repoName)) PR #\(pr.number)"
    }

    private func prefixForBuildaBotInRepoWithName(repoName: String) -> String {
        return "\(self.prefixForBuildaBot()) [\(repoName)]"
    }
    
    private func prefixForBuildaBot() -> String {
        return "BuildaBot"
    }
}

extension Array {
    
    func mapVoidAsync(transformAsync: (item: T, itemCompletion: () -> ()) -> (), completion: () -> ()) {
        self.mapAsync(transformAsync, completion: { (_) -> () in
            completion()
        })
    }
    
    func mapAsync<U>(transformAsync: (item: T, itemCompletion: (U) -> ()) -> (), completion: ([U]) -> ()) {
        
        let group = dispatch_group_create()
        var returnedValueMap = [Int: U]()

        for (index, element) in enumerate(self) {
            dispatch_group_enter(group)
            transformAsync(item: element, itemCompletion: {
                (returned: U) -> () in
                returnedValueMap[index] = returned
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            
            //we have all the returned values in a map, put it back into an array of Us
            var returnedValues = [U]()
            for i in 0 ..< returnedValueMap.count {
                returnedValues.append(returnedValueMap[i]!)
            }
            completion(returnedValues)
        }
    }
    
}
