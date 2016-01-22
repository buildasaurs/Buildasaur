//
//  SyncerLogic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 01/10/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import XcodeServerSDK
import BuildaUtils

public struct StatusAndComment {
    public let status: StatusType
    public let comment: String?
    
    public init(status: StatusType, comment: String? = nil) {
        self.status = status
        self.comment = comment
    }
}

extension HDGitHubXCBotSyncer {
    
    var _project: Project { return self.project }
    var _xcodeServer: XcodeServer { return self.xcodeServer }
    var _sourceServer: SourceServerType { return self.sourceServer }
    var _buildTemplate: BuildTemplate { return self.buildTemplate }
    var _waitForLttm: Bool { return self.config.value.waitForLttm }
    var _postStatusComments: Bool { return self.config.value.postStatusComments }
    var _watchedBranchNames: [String] { return self.config.value.watchedBranchNames }
    
    public typealias BotActions = (
        prsToSync: [(pr: PullRequestType, bot: Bot)],
        prBotsToCreate: [PullRequestType],
        branchesToSync: [(branch: BranchType, bot: Bot)],
        branchBotsToCreate: [BranchType],
        botsToDelete: [Bot])
            
    public func repoName() -> String? {
        return self._project.githubRepoName()
    }
        
    internal func syncRepoWithName(repoName: String, completion: () -> ()) {
        
        self._sourceServer.getRepo(repoName, completion: { (repo, error) -> () in
            
            if error != nil {
                //whoops, no more syncing for now
                self.notifyError(error, context: "Fetching Repo")
                completion()
                return
            }
            
            if let repo = repo {
                
                self.syncRepoWithNameAndMetadata(repoName, repo: repo, completion: completion)
            } else {
                self.notifyErrorString("Repo is nil and error is nil", context: "Fetching Repo")
                completion()
            }
        })
    }
    
    private func syncRepoWithNameAndMetadata(repoName: String, repo: RepoType, completion: () -> ()) {
        
        //pull PRs from source server
        self._sourceServer.getOpenPullRequests(repoName, completion: { (prs, error) -> () in
            
            if error != nil {
                //whoops, no more syncing for now
                self.notifyError(error, context: "Fetching PRs")
                completion()
                return
            }
            
            if let prs = prs {
                
                self.reports["All Pull Requests"] = "\(prs.count)"
                self.syncRepoWithPRs(repoName, repo: repo, prs: prs, completion: completion)
                
            } else {
                self.notifyErrorString("PRs are nil and error is nil", context: "Fetching PRs")
                completion()
            }
        })
    }
    
    private func syncRepoWithPRs(repoName: String, repo: RepoType, prs: [PullRequestType], completion: () -> ()) {
        
        //only fetch branches if there are any watched ones. there might be tens or hundreds of branches
        //so we don't want to fetch them unless user actually is watching any non-PR branches.
        if self._watchedBranchNames.count > 0 {
            
            //we have PRs, now fetch branches
            self._sourceServer.getBranchesOfRepo(repoName, completion: { (branches, error) -> () in
                
                if error != nil {
                    //whoops, no more syncing for now
                    self.notifyError(error, context: "Fetching branches")
                    completion()
                    return
                }
                
                if let branches = branches {
                    
                    self.syncRepoWithPRsAndBranches(repoName, repo: repo, prs: prs, branches: branches, completion: completion)
                } else {
                    self.notifyErrorString("Branches are nil and error is nil", context: "Fetching branches")
                    completion()
                }
            })
        } else {
            
            //otherwise call the next step immediately with an empty array for branches
            self.syncRepoWithPRsAndBranches(repoName, repo: repo, prs: prs, branches: [], completion: completion)
        }
    }
    
    private func syncRepoWithPRsAndBranches(repoName: String, repo: RepoType, prs: [PullRequestType], branches: [BranchType], completion: () -> ()) {
        
        //we have branches, now fetch bots
        self._xcodeServer.getBots({ (bots, error) -> () in
            
            if let error = error {
                //whoops, no more syncing for now
                self.notifyError(error, context: "Fetching Bots")
                completion()
                return
            }
            
            if let bots = bots {
                
                self.reports["All Bots"] = "\(bots.count)"
                
                //we have both PRs and Bots, resolve
                self.syncPRsAndBranchesAndBots(repo: repo, repoName: repoName, prs: prs, branches: branches, bots: bots, completion: {
                    
                    //everything is done, report the damage of the server's rate limit
                    if let rateLimitInfo = repo.latestRateLimitInfo {
                        
                        let report = rateLimitInfo.report
                        self.reports["Rate Limit"] = report
                        Log.info("Rate Limit: \(report)")
                    }
                    
                    completion()
                })
            } else {
                self.notifyErrorString("Nil bots even when error was nil", context: "Fetching Bots")
                completion()
            }
        })
    }
    
    public func syncPRsAndBranchesAndBots(repo repo: RepoType, repoName: String, prs: [PullRequestType], branches: [BranchType], bots: [Bot], completion: () -> ()) {
        
        let prsDescription = prs.map { (pr: PullRequestType) -> String in
            "    PR \(pr.number): \(pr.title) [\(pr.headName) -> \(pr.baseName)]"
            }.joinWithSeparator("\n")
        let branchesDescription = branches.map { (branch: BranchType) -> String in
            "    Branch [\(branch.name):\(branch.commitSHA)]" }
            .joinWithSeparator("\n")
        let botsDescription = bots.map { "    Bot \($0.name)" }.joinWithSeparator("\n")
        Log.verbose("Resolving prs:\n\(prsDescription) \nand branches:\n\(branchesDescription)\nand bots:\n\(botsDescription)")
        
        //create the changes necessary
        let botActions = self.resolvePRsAndBranchesAndBots(repoName: repoName, prs: prs, branches: branches, bots: bots)
        
        //create actions from changes, so called "SyncPairs"
        let syncPairs = self.createSyncPairsFrom(repo: repo, botActions: botActions)
        
        //start these actions
        self.applyResolvedSyncPairs(syncPairs, completion: completion)
    }
    
    public func resolvePRsAndBranchesAndBots(
        repoName repoName: String,
        prs: [PullRequestType],
        branches: [BranchType],
        bots: [Bot])
        -> BotActions {
            
            //first filter only builda's bots, don't manipulate manually created bots
            //also filter only bots that belong to this project
            let buildaBots = bots.filter { BotNaming.isBuildaBotBelongingToRepoWithName($0, repoName: repoName) }
            
            //create a map of name -> bot for fast manipulation
            var mappedBots = buildaBots.toDictionary({ $0.name })
            
            //PRs that also have a bot, prsToSync
            var prsToSync: [(pr: PullRequestType, bot: Bot)] = []
            
            //branches that also have a bot, branchesToSync
            var branchesToSync: [(branch: BranchType, bot: Bot)] = []
            
            //PRs that don't have a bot yet, to create
            var prBotsToCreate: [PullRequestType] = []
            
            //branches that don't have a bot yet, to create
            var branchBotsToCreate: [BranchType] = []
            
            //make sure every PR has a bot
            for pr in prs {
                
                let botName = BotNaming.nameForBotWithPR(pr, repoName: repoName)
                
                if let bot = mappedBots[botName] {
                    //we found a corresponding bot to this PR, add to toSync
                    prsToSync.append((pr: pr, bot: bot))
                    
                    //and remove from bots mappedBots, because we handled it
                    mappedBots.removeValueForKey(botName)
                } else {
                    //no bot found for this PR, we'll have to create one
                    prBotsToCreate.append(pr)
                }
            }
            
            //first try to find Branch objects for our watched branches
            
            //create a map of branch names to branch objects for fast lookup
            let branchesDictionary = branches.toDictionary { $0.name }
            
            //filter just the ones we want
            let foundBranchesToWatch = self._watchedBranchNames.filter({ branchesDictionary[$0] != nil })
            let branchesToWatch = foundBranchesToWatch.map({ branchesDictionary[$0]! })
            
            //what do we do with deleted branches still in the list of branches to watch long term?
            //we unwatch them right here by just keeping the valid, found branches
//            self.watchedBranchNames.value = foundBranchesToWatch
            //EDIT: let's not do that for now. i don't like the syncer changing
            //its own configuration at runtime.
            
            //go through the branches to track
            for branch in branchesToWatch {
                
                let botName = BotNaming.nameForBotWithBranch(branch, repoName: repoName)
                
                if let bot = mappedBots[botName] {
                    
                    //we found a corresponding bot to this watched Branch, add to toSync
                    branchesToSync.append((branch: branch, bot: bot))
                    
                    //and remove from bots mappedBots, because we handled it
                    mappedBots.removeValueForKey(botName)
                } else {
                    
                    //no bot found for this Branch, create one
                    branchBotsToCreate.append(branch)
                }
            }
            
            //bots that don't have a PR or a branch, to delete
            let botsToDelete = Array(mappedBots.values)
            
            return (prsToSync, prBotsToCreate, branchesToSync, branchBotsToCreate, botsToDelete)
    }
    
    public func createSyncPairsFrom(repo repo: RepoType, botActions: BotActions) -> [SyncPair] {
        
        //create sync pairs for each action needed
        let syncPRBotSyncPairs = botActions.prsToSync.map({
            SyncPair_PR_Bot(pr: $0.pr, bot: $0.bot, resolver: SyncPairPRResolver()) as SyncPair
        })
        let createBotFromPRSyncPairs = botActions.prBotsToCreate.map({ SyncPair_PR_NoBot(pr: $0) as SyncPair })
        let syncBranchBotSyncPairs = botActions.branchesToSync.map({
            SyncPair_Branch_Bot(branch: $0.branch, bot: $0.bot, resolver: SyncPairBranchResolver()) as SyncPair
        })
        let createBotFromBranchSyncPairs = botActions.branchBotsToCreate.map({ SyncPair_Branch_NoBot(branch: $0, repo: repo) as SyncPair })
        let deleteBotSyncPairs = botActions.botsToDelete.map({ SyncPair_Deletable_Bot(bot: $0) as SyncPair })
        
        //here feel free to inject more things to be done during a sync
        
        //put them all into one array
        let toCreate: [SyncPair] = createBotFromPRSyncPairs + createBotFromBranchSyncPairs
        let toSync: [SyncPair] = syncPRBotSyncPairs + syncBranchBotSyncPairs
        let toDelete: [SyncPair] = deleteBotSyncPairs
        
        let syncPairsRaw: [SyncPair] = toCreate + toSync + toDelete
        
        //prepared sync pair
        let syncPairs = syncPairsRaw.map({
            (syncPair: SyncPair) -> SyncPair in
            syncPair.syncer = self
            return syncPair
        })
        
        if toCreate.count > 0 {
            self.reports["Created bots"] = "\(toCreate.count)"
        }
        if toDelete.count > 0 {
            self.reports["Deleted bots"] = "\(toDelete.count)"
        }
        if toSync.count > 0 {
            self.reports["Synced bots"] = "\(toSync.count)"
        }
        
        return syncPairs
    }
    
    private func applyResolvedSyncPairs(syncPairs: [SyncPair], completion: () -> ()) {
        
        //actually kick the sync pairs off
        let group = dispatch_group_create()
        for i in syncPairs {
            dispatch_group_enter(group)
            i.start({ (error) -> () in
                if let error = error {
                    self.notifyError(error, context: "SyncPair: \(i.syncPairName())")
                }
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), completion)
    }
}
