//
//  SyncPair_PR_Bot_Tests.swift
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

//for tuples, XCTAssert... doesn't work for them
func XCTBAssertNil<T>(@autoclosure expression:  () -> T?, message: String = "Must be nil",
    file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssert(expression() == nil, message, file:file, line:line);
}

func XCTBAssertNotNil<T>(@autoclosure expression:  () -> T?, message: String = "Must not be nil",
    file: String = __FILE__, line: UInt = __LINE__) {
        XCTAssert(expression() != nil, message, file:file, line:line);
}

class SyncPair_PR_Bot_Tests: XCTestCase {
    
    func mockedPRAndBot() -> (PullRequest, Bot) {

        let pr = MockPullRequest(number: 1, title: "Awesomified The Engine")
        let bot = MockBot(name: "BuildaBot [me/Repo] PR #1")

        return (pr, bot)
    }
    
    func testNoIntegrationsYet() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [Integration]()
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        XCTAssertEqual(actions.integrationsToCancel?.count ?? 0, 0)
        XCTBAssertNil(actions.githubStatusToSet)
        XCTAssertNotNil(actions.startNewIntegrationBot)
    }
    
    func testFirstIntegrationPending() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Pending)
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        XCTAssertEqual(actions.integrationsToCancel?.count ?? 0, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Pending)
    }
    
    func testMultipleIntegrationsPending() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Pending),
            MockIntegration(number: 2, step: Integration.Step.Pending),
            MockIntegration(number: 3, step: Integration.Step.Pending)
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        //should cancel all except for the last one
        let toCancel = Set(actions.integrationsToCancel!)
        XCTAssertEqual(toCancel.count, 2)
        XCTAssertTrue(toCancel.contains(integrations[0]))
        XCTAssertTrue(toCancel.contains(integrations[1]))
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Pending)
    }
    
    func testOneIntegrationRunning() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building),
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Pending)
    }
    
    func testOneIntegrationTestsFailed() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Completed, sha: "head_sha", result: Integration.Result.TestFailures)
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Failure)
    }
    
    func testOneIntegrationSuccess() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Completed, sha: "head_sha", result: Integration.Result.Succeeded)
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Success)
    }
    
    func testTwoIntegrationOneRunningOnePending() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building, sha: "head_sha"),
            MockIntegration(number: 2, step: Integration.Step.Pending, sha: "head_sha")
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 1)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.githubStatusToSet)
        XCTAssertEqual(actions.githubStatusToSet!.status.status.state, Status.State.Pending)
    }

    func testTwoIntegrationsDifferentCommits() {
        
        let (pr, bot) = self.mockedPRAndBot()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building, sha: "head_sha_old"),
        ]
        
        let actions = SyncPair_PR_Bot.syncPRWithBotIntegrations(pr: pr, bot: bot, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 1)
        XCTAssertNotNil(actions.startNewIntegrationBot)
        XCTBAssertNil(actions.githubStatusToSet) //no change
    }
    
    //TODO: add more complicated cases
    
}
