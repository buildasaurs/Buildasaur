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
import BuildaCIServer
import Buildasaur

class SyncerTests: XCTestCase {

    var syncer: HDGitHubXCBotSyncer!
    
    override func setUp() {
        super.setUp()
        self.syncer = self.mockedSyncer()
    }
    
    func mockedSyncer() -> HDGitHubXCBotSyncer {
        
        let xcodeServer = MockXcodeServer()
        let githubServer = MockGitHubServer()
        let project = MockLocalSource()
        let syncInterval = 15.0
        let waitForLttm = true
        let postStatusComments = true
        
        let syncer = HDGitHubXCBotSyncer(integrationServer: xcodeServer, sourceServer: githubServer, localSource: project, syncInterval: syncInterval, waitForLttm: waitForLttm, postStatusComments: postStatusComments)
        return syncer
    }
    
    //MARK: Creating change actions from input data (PRs and Bots)
    
    func testCreatingChangeActions_NoPRs_NoBots() {
        
        let (toSync, toCreate, toDelete) = self.syncer.resolvePRsAndBots(repoName: "me/Repo", prs: [], bots: [])
        XCTAssertEqual(toSync.count, 0)
        XCTAssertEqual(toCreate.count, 0)
        XCTAssertEqual(toDelete.count, 0)
    }
    
    func testCreatingChangeActions_MultiplePR_NoBots() {
        
        let prs = [
            MockPullRequest(number: 4, title: ""),
            MockPullRequest(number: 7, title: "")
        ]
        
        let (toSync, toCreate, toDelete) = self.syncer.resolvePRsAndBots(repoName: "me/Repo", prs: prs, bots: [])
        XCTAssertEqual(toSync.count, 0)
        XCTAssertEqual(toCreate.count, 2)
        XCTAssertEqual(toDelete.count, 0)
    }
    
    func testCreatingChangeActions_NoPR_Bots() {
        
        let bots = [
            MockBot(name: "bot1"),
            MockBot(name: "BuildaBot [me/Repo] bot2")
        ]
        
        let (toSync, toCreate, toDelete) = self.syncer.resolvePRsAndBots(repoName: "me/Repo", prs: [], bots: bots)
        XCTAssertEqual(toSync.count, 0)
        XCTAssertEqual(toCreate.count, 0)
        XCTAssertEqual(toDelete.count, 1) //should only be one, because the first bot should get ignored, since it doesn't belong to me/Repo (judging by its name prefix)
    }
    
    func testCreatingChangeActions_PRs_Bots() {
        
        let bots = [
            MockBot(name: "bot1"), //this should get ignored
            MockBot(name: "BuildaBot [me/Repo] PR #4"),
            MockBot(name: "BuildaBot [me/Repo] PR #8")
        ]
        
        let prs = [
            MockPullRequest(number: 4, title: ""),
            MockPullRequest(number: 7, title: "")
        ]
        
        let (toSync, toCreate, toDelete) = self.syncer.resolvePRsAndBots(repoName: "me/Repo", prs: prs, bots: bots)
        XCTAssertEqual(toSync.count, 1)
        XCTAssertEqual(toSync.first!.bot.name, "BuildaBot [me/Repo] PR #4")
        XCTAssertEqual(toSync.first!.pr.number, 4)
        XCTAssertEqual(toCreate.count, 1)
        XCTAssertEqual(toCreate.first!.number, 7)
        XCTAssertEqual(toDelete.count, 1)
        XCTAssertEqual(toDelete.first!.name, "BuildaBot [me/Repo] PR #8")
    }
    
}







