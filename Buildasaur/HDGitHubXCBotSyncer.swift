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
    let waitForLttm: Bool
    let postStatusComments: Bool
    
    public typealias GitHubStatusAndComment = (status: Status, comment: String?)
    
    public init(integrationServer: XcodeServer, sourceServer: GitHubServer, localSource: LocalSource,
        syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool) {
        
        self.github = sourceServer
        self.xcodeServer = integrationServer
        self.localSource = localSource
        self.waitForLttm = waitForLttm
        self.postStatusComments = postStatusComments
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
            super.init(syncInterval: syncInterval)
            
        } else {
            
            self.github = nil
            self.xcodeServer = nil
            self.localSource = nil
            self.waitForLttm = true
            self.postStatusComments = true
            super.init(syncInterval: 0)
            return nil
        }
    }
    
    func jsonify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        dict["sync_interval"] = self.syncInterval
        dict["project_path"] = self.localSource.url.absoluteString
        dict["server_host"] = self.xcodeServer.config.host
        dict["wait_for_lttm"] = self.waitForLttm
        dict["post_status_comments"] = self.postStatusComments
        return dict
    }
    
    func repoName() -> String? {
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
                            
                            //we have both PRs and Bots, resolve
                            self.syncPRsAndBots(repoName: repoName, prs: prs, bots: bots, completion: {
                                
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
                    
                } else {
                    self.notifyErrorString("PRs are nil and error is nil", context: "Fetching PRs")
                    completion()
                }
            })
            
        } else {
            self.notifyErrorString("Nil repo name", context: "Syncing")
            completion()
        }
    }
    
    public func syncPRsAndBots(#repoName: String, prs: [PullRequest], bots: [Bot], completion: () -> ()) {
        
        let prsDescription = prs.map({ "\n\tPR \($0.number): \($0.title) [\($0.head.ref) -> \($0.base.ref))]" }) + ["\n"]
        let botsDescription = bots.map({ "\n\t\($0.name)" }) + ["\n"]
        Log.verbose("Resolving prs:\n\(prsDescription) \nand bots:\n\(botsDescription)")
        
        //create the changes necessary
        let (toSync, toCreate, toDelete) = self.resolvePRsAndBots(repoName: repoName, prs: prs, bots: bots)
        
        //create actions from changes, so called "SyncPairs"
        let syncPairs = self.createSyncPairsFrom(toSync: toSync, toCreate: toCreate, toDelete: toDelete)
        
        //start these actions
        self.applyResolvedSyncPairs(syncPairs, completion: completion)
    }
    
    public func resolvePRsAndBots(#repoName: String, prs: [PullRequest], bots: [Bot]) -> (toSync: [(pr: PullRequest, bot: Bot)], toCreate: [PullRequest], toDelete: [Bot]) {
        
        //first filter only builda's bots, don't manipulate manually created bots
        //also filter only bots that belong to this project
        let buildaBots = bots.filter { BotNaming.isBuildaBotBelongingToRepoWithName($0, repoName: repoName) }
        
        //create a map of name -> bot for fast manipulation
        var mappedBots = [String: Bot]()
        for bot in buildaBots { mappedBots[bot.name] = bot }
        
        //PRs that also have a bot, toSync
        var toSync: [(pr: PullRequest, bot: Bot)] = []
        
        //PRs that don't have a bot yet, to create
        var toCreate: [PullRequest] = []
        for pr in prs {
            
            let botName = BotNaming.nameForBotWithPR(pr, repoName: repoName)
            
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
        
        //bots that don't have a PR, to delete
        let toDelete = mappedBots.values.array
        
        return (toSync, toCreate, toDelete)
    }
    
    public func createSyncPairsFrom(#toSync: [(pr: PullRequest, bot: Bot)], toCreate: [PullRequest], toDelete: [Bot]) -> [SyncPair] {
        
        //create sync pairs for each action needed
        let deleteBotSyncPairs = toDelete.map({ SyncPair_NoPR_Bot(bot: $0) as SyncPair })
        let createBotSyncPairs = toCreate.map({ SyncPair_PR_NoBot(pr: $0) as SyncPair })
        let syncPRBotSyncPairs = toSync.map({ SyncPair_PR_Bot(pr: $0.pr, bot: $0.bot) as SyncPair })
        
        //here feel free to inject more things to be done during a sync
        
        //put them all into one array
        let syncPairsRaw: [SyncPair] = deleteBotSyncPairs + createBotSyncPairs + syncPRBotSyncPairs

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
