//
//  SummaryCreator.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/15/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaUtils
import BuildaGitServer

class SummaryBuilder {
    
    var lines: [String] = []
    let resultString: String
    var linkBuilder: (Integration) -> String? = { _ in nil }
    
    init() {
        self.resultString = "*Result*: "
    }
    
    //MARK: high level
    
    func buildPassing(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Success, description: "Build passed!", targetUrl: linkToIntegration)
        
        let buildResultSummary = integration.buildResultSummary!
        if integration.result == .Succeeded {
            self.appendTestsPassed(buildResultSummary)
        } else if integration.result == .Warnings {
            self.appendWarnings(buildResultSummary)
        } else if integration.result == .AnalyzerWarnings {
            self.appendAnalyzerWarnings(buildResultSummary)
        }
        
        //and code coverage
        self.appendCodeCoverage(buildResultSummary)
        
        return self.buildWithStatus(status)
    }
    
    func buildFailingTests(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Failure, description: "Build failed tests!", targetUrl: linkToIntegration)
        let buildResultSummary = integration.buildResultSummary!
        self.appendTestFailure(buildResultSummary)
        return self.buildWithStatus(status)
    }
    
    func buildErrorredIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Error, description: "Build error!", targetUrl: linkToIntegration)
        
        self.appendErrors(integration)
        return self.buildWithStatus(status)
    }
    
    func buildCanceledIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Error, description: "Build canceled!", targetUrl: linkToIntegration)
        
        self.appendCancel()
        return self.buildWithStatus(status)
    }
    
    func buildEmptyIntegration() -> StatusAndComment {
        
        let status = self.createStatus(.NoState, description: nil, targetUrl: nil)
        return self.buildWithStatus(status)
    }
    
    //MARK: utils
    
    private func createStatus(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        fatalError()
//        let status = self.syncer.createStatusFromState(state, description: description, targetUrl: targetUrl)
    }
    
    func addBaseCommentFromIntegration(integration: Integration) {
        
        var integrationText = "Integration \(integration.number)"
        if let link = self.linkBuilder(integration) {
            //linkify
            integrationText = "[\(integrationText)](\(link))"
        }
        
        self.lines.append("Result of \(integrationText)")
        self.lines.append("---")
        
        if let duration = self.formattedDurationOfIntegration(integration) {
            self.lines.append("*Duration*: " + duration)
        }
    }
    
    func appendTestsPassed(buildResultSummary: BuildResultSummary) {
        
        let testsCount = buildResultSummary.testsCount
        let testSection = testsCount > 0 ? "All \(testsCount) " + "test".pluralizeStringIfNecessary(testsCount) + " passed. " : ""
        self.lines.append(self.resultString + "**Perfect build!** \(testSection):+1:")
    }
    
    func appendWarnings(buildResultSummary: BuildResultSummary) {
        
        let warningCount = buildResultSummary.warningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "All \(testsCount) tests passed, but please **fix \(warningCount) " + "warning".pluralizeStringIfNecessary(warningCount) + "**.")
    }
    
    func appendAnalyzerWarnings(buildResultSummary: BuildResultSummary) {
        
        let analyzerWarningCount = buildResultSummary.analyzerWarningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "All \(testsCount) tests passed, but please **fix \(analyzerWarningCount) " + "analyzer warning".pluralizeStringIfNecessary(analyzerWarningCount) + "**.")
    }
    
    func appendCodeCoverage(buildResultSummary: BuildResultSummary) {
        
        let codeCoveragePercentage = buildResultSummary.codeCoveragePercentage
        if codeCoveragePercentage > 0 {
            self.lines.append("*Test Coverage*: \(codeCoveragePercentage)%")
        }
    }
    
    func appendTestFailure(buildResultSummary: BuildResultSummary) {
        
        let testFailureCount = buildResultSummary.testFailureCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "**Build failed \(testFailureCount) " + "test".pluralizeStringIfNecessary(testFailureCount) + "** out of \(testsCount)")
    }
    
    func appendErrors(integration: Integration) {
        
        let errorCount: Int = integration.buildResultSummary?.errorCount ?? -1
        self.lines.append(self.resultString + "**\(errorCount) " + "error".pluralizeStringIfNecessary(errorCount) + ", failing state: \(integration.result!.rawValue)**")
    }
    
    func appendCancel() {
        
        //TODO: find out who canceled it and add it to the comment?
        self.lines.append("Build was **manually canceled**.")
    }
    
    func buildWithStatus(status: StatusType) -> StatusAndComment {
        
        let comment: String?
        if lines.count == 0 {
            comment = nil
        } else {
            comment = lines.joinWithSeparator("\n")
        }
        return StatusAndComment(status: status, comment: comment)
    }
}

extension SummaryBuilder {
    
    func formattedDurationOfIntegration(integration: Integration) -> String? {
        
        if let seconds = integration.duration {
            
            let result = TimeUtils.secondsToNaturalTime(Int(seconds))
            return result
            
        } else {
            Log.error("No duration provided in integration \(integration)")
            return "[NOT PROVIDED]"
        }
    }
}
