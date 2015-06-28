//
//  HDGitHubXCBotSyncer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import BuildaUtils
import XcodeServerSDK

public class HDGitHubXCBotSyncer : Syncer {
    
    public typealias BotActions = (
        prsToSync: [(pr: PullRequest, bot: Bot)],
        prBotsToCreate: [PullRequest],
        branchesToSync: [(branch: Branch, bot: Bot)],
        branchBotsToCreate: [Branch],
        botsToDelete: [Bot])
    
    let github: GitHubServer!
    let xcodeServer: XcodeServer!
    let localSource: LocalSource!
    let waitForLttm: Bool
    let postStatusComments: Bool
    public var watchedBranchNames: [String]
    
    public typealias GitHubStatusAndComment = (status: Status, comment: String?)
    
    public init(integrationServer: XcodeServer, sourceServer: GitHubServer, localSource: LocalSource,
        syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool, watchedBranchNames: [String]) {
            
            self.github = sourceServer
            self.xcodeServer = integrationServer
            self.localSource = localSource
            self.waitForLttm = waitForLttm
            self.postStatusComments = postStatusComments
            self.watchedBranchNames = watchedBranchNames
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
            self.waitForLttm = json.optionalBoolForKey("wait_for_lttm") ?? true
            self.postStatusComments = json.optionalBoolForKey("post_status_comments") ?? true
            self.watchedBranchNames = json.optionalArrayForKey("watched_branches") as? [String] ?? []
            super.init(syncInterval: syncInterval)
            
        } else {
            
            self.github = nil
            self.xcodeServer = nil
            self.localSource = nil
            self.waitForLttm = true
            self.postStatusComments = true
            self.watchedBranchNames = []
            super.init(syncInterval: 0)
            return nil
        }
    }
    
    func jsonify() -> NSDictionary {
        
        let dict = NSMutableDictionary()
        dict["sync_interval"] = self.syncInterval
        dict["project_path"] = self.localSource.url.absoluteString
        dict["server_host"] = self.xcodeServer.config.host
        dict["wait_for_lttm"] = self.waitForLttm
        dict["post_status_comments"] = self.postStatusComments
        dict["watched_branches"] = self.watchedBranchNames
        return dict
    }
    
    func repoName() -> String? {
        return self.localSource.githubRepoName()
    }
    
    //TODO: migrate this shit to RAC, the callback hell below hurts my eyes (you've been warned)
    
    public override func sync(completion: () -> ()) {
        
        if let repoName = self.repoName() {
            
            self.syncRepoWithName(repoName, completion: completion)
        } else {
            self.notifyErrorString("Nil repo name", context: "Syncing")
            completion()
        }
    }
    
    private func syncRepoWithName(repoName: String, completion: () -> ()) {
        
        self.github.getRepo(repoName, completion: { (repo, error) -> () in
            
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
    
    private func syncRepoWithNameAndMetadata(repoName: String, repo: Repo, completion: () -> ()) {
        
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
                self.syncRepoWithPRs(repoName, repo: repo, prs: prs, completion: completion)
                
            } else {
                self.notifyErrorString("PRs are nil and error is nil", context: "Fetching PRs")
                completion()
            }
        })
    }
    
    private func syncRepoWithPRs(repoName: String, repo: Repo, prs: [PullRequest], completion: () -> ()) {
        
        //only fetch branches if there are any watched ones. there might be tens or hundreds of branches
        //so we don't want to fetch them unless user actually is watching any non-PR branches.
        if self.watchedBranchNames.count > 0 {
            
            //we have PRs, now fetch branches
            self.github.getBranchesOfRepo(repoName, completion: { (branches, error) -> () in
                
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
    
    private func syncRepoWithPRsAndBranches(repoName: String, repo: Repo, prs: [PullRequest], branches: [Branch], completion: () -> ()) {
        
        //we have branches, now fetch bots
        self.xcodeServer.getBots({ (bots, error) -> () in
            
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
                    
                    //everything is done, report the damage of GitHub rate limit
                    if let rateLimitInfo = self.github.latestRateLimitInfo {
                        
                        let report = rateLimitInfo.getReport()
                        self.reports["GitHub Rate Limit"] = report
                        Log.info("GitHub Rate Limit: \(report)")
                    }
                    
                    completion()
                })
            } else {
                self.notifyErrorString("Nil bots even when error was nil", context: "Fetching Bots")
                completion()
            }
        })
    }
    
    public func syncPRsAndBranchesAndBots(repo repo: Repo, repoName: String, prs: [PullRequest], branches: [Branch], bots: [Bot], completion: () -> ()) {
        
        let prsDescription = prs.map({ "\n\tPR \($0.number): \($0.title) [\($0.head.ref) -> \($0.base.ref))]" }) + ["\n"]
        let branchesDescription = branches.map({ "\n\tBranch [\($0.name):\($0.commit.sha)]" }) + ["\n"]
        let botsDescription = bots.map({ "\n\tBot \($0.name)" }) + ["\n"]
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
        prs: [PullRequest],
        branches: [Branch],
        bots: [Bot])
        -> BotActions {
            
            //first filter only builda's bots, don't manipulate manually created bots
            //also filter only bots that belong to this project
            let buildaBots = bots.filter { BotNaming.isBuildaBotBelongingToRepoWithName($0, repoName: repoName) }
            
            //create a map of name -> bot for fast manipulation
            var mappedBots = buildaBots.toDictionary({ $0.name })
            
            //PRs that also have a bot, prsToSync
            var prsToSync: [(pr: PullRequest, bot: Bot)] = []
            
            //branches that also have a bot, branchesToSync
            var branchesToSync: [(branch: Branch, bot: Bot)] = []
            
            //PRs that don't have a bot yet, to create
            var prBotsToCreate: [PullRequest] = []
            
            //branches that don't have a bot yet, to create
            var branchBotsToCreate: [Branch] = []
            
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
            let foundBranchesToWatch = self.watchedBranchNames.filter({ branchesDictionary[$0] != nil })
            let branchesToWatch = foundBranchesToWatch.map({ branchesDictionary[$0]! })
            
            //what do we do with deleted branches still in the list of branches to watch long term?
            //we unwatch them right here by just keeping the valid, found branches
            self.watchedBranchNames = foundBranchesToWatch
            
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
            let botsToDelete = mappedBots.values.array
            
            return (prsToSync, prBotsToCreate, branchesToSync, branchBotsToCreate, botsToDelete)
    }
    
    public func createSyncPairsFrom(repo repo: Repo, botActions: BotActions) -> [SyncPair] {
        
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
