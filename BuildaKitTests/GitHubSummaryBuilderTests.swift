//
//  SummaryBuilderTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/15/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest
import XcodeServerSDK
import BuildaGitServer
@testable import BuildaKit
import Nimble

class GitHubSummaryBuilderTests: XCTestCase {
    
    //MARK: utils
    
    func integration(result: Integration.Result, buildResultSummary: BuildResultSummary) -> Integration {
        let integration = MockIntegration(number: 15, step: .Completed, result: result, buildResultSummary: buildResultSummary)
        return integration
    }
    
    func linkBuilder() -> ((Integration) -> String?) {
        return { integration -> String? in
            return "https://link/to/\(integration.id)"
        }
    }
    
    //MARK: tests
    
    func testPassing_noTests_noCoverage_noLink() {
        
        let buildResultSummary = MockBuildResultSummary()
        let integration = self.integration(.Succeeded, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: **Perfect build!** :+1:"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
        expect(result.status.targetUrl).to(beNil())
    }
    
    func testPassing_noTests_noCoverage_withLink() {
        
        let buildResultSummary = MockBuildResultSummary()
        let integration = self.integration(.Succeeded, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        summary.linkBuilder = self.linkBuilder()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of [Integration 15](https://link/to/d3884f0ab7df9c699bc81405f4045ec6)\n---\n*Duration*: 28 seconds\n*Result*: **Perfect build!** :+1:"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        let exp_link = "https://link/to/d3884f0ab7df9c699bc81405f4045ec6"
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
        expect(result.status.targetUrl) == exp_link
    }
    
    func testPassing_noTests_withCoverage() {
        
        let buildResultSummary = MockBuildResultSummary(codeCoveragePercentage: 12)
        let integration = self.integration(.Succeeded, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: **Perfect build!** :+1:\n*Test Coverage*: 12%"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testPassing_withTests_withCoverage() {
        
        //got 99 tests but failing ain't one
        let buildResultSummary = MockBuildResultSummary(testsCount: 99, codeCoveragePercentage: 12)
        let integration = self.integration(.Succeeded, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: **Perfect build!** All 99 tests passed. :+1:\n*Test Coverage*: 12%"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testPassing_withTests_withWarnings() {
        
        let buildResultSummary = MockBuildResultSummary(testsCount: 99, warningCount: 2, codeCoveragePercentage: 12)
        let integration = self.integration(.Warnings, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: All 99 tests passed, but please **fix 2 warnings**.\n*Test Coverage*: 12%"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testPassing_withTests_withAnalyzerWarnings() {
        
        let buildResultSummary = MockBuildResultSummary(analyzerWarningCount: 3, testsCount: 99, codeCoveragePercentage: 12)
        let integration = self.integration(.AnalyzerWarnings, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildPassing(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: All 99 tests passed, but please **fix 3 analyzer warnings**.\n*Test Coverage*: 12%"
        let exp_status = "Build passed!"
        let exp_state = BuildState.Success
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testFailingTests() {
        
        //got 99 tests but failing's just one
        let buildResultSummary = MockBuildResultSummary(testFailureCount: 1, testsCount: 99)
        let integration = self.integration(.TestFailures, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildFailingTests(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: **Build failed 1 test** out of 99"
        let exp_status = "Build failed tests!"
        let exp_state = BuildState.Failure
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testErrors() {
        
        let buildResultSummary = MockBuildResultSummary(errorCount: 4)
        let integration = self.integration(.BuildErrors, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildErrorredIntegration(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\n*Result*: **4 errors, failing state: build-errors**"
        let exp_status = "Build error!"
        let exp_state = BuildState.Error
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }

    func testCanceled() {
        
        let buildResultSummary = MockBuildResultSummary()
        let integration = self.integration(.Canceled, buildResultSummary: buildResultSummary)
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildCanceledIntegration(integration)
        
        let exp_comment = "Result of Integration 15\n---\n*Duration*: 28 seconds\nBuild was **manually canceled**."
        let exp_status = "Build canceled!"
        let exp_state = BuildState.Error
        expect(result.comment) == exp_comment
        expect(result.status.description) == exp_status
        expect(result.status.state) == exp_state
    }
    
    func testEmpty() {
        
        let summary = SummaryBuilder()
        summary.statusCreator = MockGitHubServer()
        let result = summary.buildEmptyIntegration()
        
        let exp_state = BuildState.NoState
        expect(result.comment).to(beNil())
        expect(result.status.description).to(beNil())
        expect(result.status.state) == exp_state
    }
}
