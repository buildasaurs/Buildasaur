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
import XcodeServerSDK
import Buildasaur
import BuildaKit

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
    
    func mockedPRAndBotAndCommit() -> (PullRequestType, Bot, String, BuildStatusCreator) {

        let pr: PullRequestType = MockPullRequest(number: 1, title: "Awesomified The Engine")
        let bot = MockBot(name: "BuildaBot [me/Repo] PR #1")
        let commit = pr.headCommitSHA
        let buildStatusCreator = MockBuildStatusCreator()
        
        return (pr, bot, commit, buildStatusCreator)
    }
    
    func testNoIntegrationsYet() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [Integration]()
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        XCTAssertEqual(actions.integrationsToCancel?.count ?? 0, 0)
        XCTBAssertNil(actions.statusToSet)
        XCTAssertNotNil(actions.startNewIntegrationBot)
    }
    
    func testFirstIntegrationPending() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Pending)
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        XCTAssertEqual(actions.integrationsToCancel?.count ?? 0, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Pending)
    }
    
    func testMultipleIntegrationsPending() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Pending),
            MockIntegration(number: 2, step: Integration.Step.Pending),
            MockIntegration(number: 3, step: Integration.Step.Pending)
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        //should cancel all except for the last one
        let toCancel = Set(actions.integrationsToCancel!)
        XCTAssertEqual(toCancel.count, 2)
        XCTAssertTrue(toCancel.contains(integrations[0]))
        XCTAssertTrue(toCancel.contains(integrations[1]))
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Pending)
    }
    
    func testOneIntegrationRunning() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building),
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Pending)
    }
    
    func testOneIntegrationTestsFailed() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Completed, sha: "head_sha", result: Integration.Result.TestFailures)
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Failure)
    }
    
    func testOneIntegrationSuccess() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Completed, sha: "head_sha", result: Integration.Result.Succeeded)
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 0)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Success)
    }
    
    func testTwoIntegrationOneRunningOnePending() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building, sha: "head_sha"),
            MockIntegration(number: 2, step: Integration.Step.Pending, sha: "head_sha")
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 1)
        XCTAssertNil(actions.startNewIntegrationBot)
        XCTBAssertNotNil(actions.statusToSet)
        XCTAssertEqual(actions.statusToSet!.status.status.state, BuildState.Pending)
    }

    func testTwoIntegrationsDifferentCommits() {
        
        let (pr, bot, commit, statusCreator) = self.mockedPRAndBotAndCommit()
        let integrations = [
            MockIntegration(number: 1, step: Integration.Step.Building, sha: "old_head_sha"),
        ]
        
        let actions = SyncPairPRResolver().resolveActionsForCommitAndIssueWithBotIntegrations(commit, issue: pr, bot: bot, hostname: "localhost", buildStatusCreator: statusCreator, integrations: integrations)
        
        XCTAssertEqual(actions.integrationsToCancel!.count, 1)
        XCTAssertNotNil(actions.startNewIntegrationBot)
        XCTBAssertNil(actions.statusToSet) //no change
    }
    
    //TODO: add more complicated cases
    
}
