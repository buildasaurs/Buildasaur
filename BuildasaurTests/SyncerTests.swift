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

    func mockedSyncer() -> HDGitHubXCBotSyncer {
        class MockXcodeServer: XcodeServer {
            init() {
                let config = XcodeServerConfig(host: "", user: "", password: "")
                super.init(config: config, endpoints: XcodeServerEndPoints(serverConfig: config))
            }
        }
        
        class MockGitHubServer: GitHubServer {
            init() {
                super.init(endpoints: GitHubEndpoints(baseURL: "", token: ""))
            }
        }
        
        class MockLocalSource: LocalSource {
            override init() {
                super.init()
            }
            required init?(json: NSDictionary) { fatalError("init(json:) has not been implemented") }
        }
        
        let xcodeServer = MockXcodeServer()
        let githubServer = MockGitHubServer()
        let project = MockLocalSource()
        let syncInterval = 15.0
        let waitForLttm = true
        let postStatusComments = true
        
        let syncer = HDGitHubXCBotSyncer(integrationServer: xcodeServer, sourceServer: githubServer, localSource: project, syncInterval: syncInterval, waitForLttm: waitForLttm, postStatusComments: postStatusComments)
        return syncer
    }
    
    func testCreatingChangeActions() {
        
        let syncer = self.mockedSyncer()
        let (toSync, toCreate, toDelete) = syncer.resolvePRsAndBots(repoName: "Repo", prs: [], bots: [])
        XCTAssert(toSync.count == 0)
        XCTAssert(toCreate.count == 0)
        XCTAssert(toDelete.count == 0)
    }
    
    //TODO: figure out an easy way to mock PRs, Bots etc
}







