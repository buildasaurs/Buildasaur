//
//  SyncerTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XCTest
import BuildaUtils
import BuildaGitServer
import XcodeServerSDK
import Buildasaur
import BuildaKit

class SyncerTests: XCTestCase {

    var syncer: StandardSyncer!
    
    override func setUp() {
        super.setUp()
        self.syncer = self.mockedSyncer()
    }
    
    override func tearDown() {
        self.syncer = nil
        super.tearDown()
    }
    
    func mockedSyncer(config: SyncerConfig = SyncerConfig()) -> StandardSyncer {
        
        let xcodeServer = MockXcodeServer()
        let githubServer = MockGitHubServer()
        let project = MockProject()
        let template = MockTemplate.new()
        
        let syncer = StandardSyncer(
            integrationServer: xcodeServer,
            sourceServer: githubServer,
            project: project,
            buildTemplate: template,
            triggers: [],
            config: config)
        return syncer
    }
    
    //MARK: Creating change actions from input data (PRs and Bots)
    
    func testCreatingChangeActions_NoPRs_NoBots() {
        
        let botActions = self.syncer.resolvePRsAndBranchesAndBots(repoName: "me/Repo", prs: [], branches: [], bots: [])
        
        XCTAssertEqual(botActions.prsToSync.count, 0)
        XCTAssertEqual(botActions.prBotsToCreate.count, 0)
        XCTAssertEqual(botActions.branchesToSync.count, 0)
        XCTAssertEqual(botActions.branchBotsToCreate.count, 0)
        XCTAssertEqual(botActions.botsToDelete.count, 0)
    }
    
    func testCreatingChangeActions_MultiplePR_NoBots() {
        
        let prs: [PullRequestType] = [
            MockPullRequest(number: 4, title: ""),
            MockPullRequest(number: 7, title: "")
        ]
        
        let botActions = self.syncer.resolvePRsAndBranchesAndBots(repoName: "me/Repo", prs: prs, branches: [], bots: [])
        
        XCTAssertEqual(botActions.prsToSync.count, 0)
        XCTAssertEqual(botActions.prBotsToCreate.count, 2)
        XCTAssertEqual(botActions.branchesToSync.count, 0)
        XCTAssertEqual(botActions.branchBotsToCreate.count, 0)
        XCTAssertEqual(botActions.botsToDelete.count, 0)
    }
    
    func testCreatingChangeActions_NoPR_Bots() {
        
        let bots = [
            MockBot(name: "bot1"),
            MockBot(name: "BuildaBot [me/Repo] bot2")
        ]
        
        let botActions = self.syncer.resolvePRsAndBranchesAndBots(repoName: "me/Repo", prs: [], branches: [], bots: bots)
        
        XCTAssertEqual(botActions.prsToSync.count, 0)
        XCTAssertEqual(botActions.prBotsToCreate.count, 0)
        XCTAssertEqual(botActions.branchesToSync.count, 0)
        XCTAssertEqual(botActions.branchBotsToCreate.count, 0)
        XCTAssertEqual(botActions.botsToDelete.count, 1) //should only be one, because the first bot should get ignored, since it doesn't belong to me/Repo (judging by its name prefix)
    }
    
    func testCreatingChangeActions_PRs_Bots() {
        
        let bots = [
            MockBot(name: "bot1"), //this should get ignored
            MockBot(name: "BuildaBot [me/Repo] PR #4"),
            MockBot(name: "BuildaBot [me/Repo] PR #8"),
            MockBot(name: "BuildaBot [me/Repo] |-> cd/broke_something"),
            MockBot(name: "BuildaBot [me/Repo] |-> gh/bot_to_delete"),
        ]
        
        let prs: [PullRequestType] = [
            MockPullRequest(number: 4, title: ""),
            MockPullRequest(number: 7, title: "")
        ]
        
        let branches: [BranchType] = [
            MockBranch(name: "cd/broke_something"),
            MockBranch(name: "ab/fixed_errthing"),
            MockBranch(name: "ef/migrating_from_php_to_mongo_db")
        ]
        
        var config = SyncerConfig()
        config.watchedBranchNames = [
            "cd/broke_something",
            "ef/migrating_from_php_to_mongo_db"
        ]
        let syncer = self.mockedSyncer(config)
        
        let botActions = syncer.resolvePRsAndBranchesAndBots(repoName: "me/Repo", prs: prs, branches: branches, bots: bots)

        XCTAssertEqual(botActions.prsToSync.count, 1)
        XCTAssertEqual(botActions.prsToSync.first!.bot.name, "BuildaBot [me/Repo] PR #4")
        XCTAssertEqual(botActions.prsToSync.first!.pr.number, 4)
        XCTAssertEqual(botActions.prBotsToCreate.count, 1)
        XCTAssertEqual(botActions.prBotsToCreate.first!.number, 7)
        XCTAssertEqual(botActions.branchesToSync.count, 1)
        XCTAssertEqual(botActions.branchesToSync.first!.branch.name, "cd/broke_something")
        XCTAssertEqual(botActions.branchBotsToCreate.count, 1)
        XCTAssertEqual(botActions.branchBotsToCreate.first!.name, "ef/migrating_from_php_to_mongo_db")
        XCTAssertEqual(botActions.botsToDelete.count, 2)
        let toDelete = Set(botActions.botsToDelete.map({ $0.name }))
        XCTAssertTrue(toDelete.contains("BuildaBot [me/Repo] PR #8"))
        XCTAssertTrue(toDelete.contains("BuildaBot [me/Repo] |-> gh/bot_to_delete"))
    }
    
}







