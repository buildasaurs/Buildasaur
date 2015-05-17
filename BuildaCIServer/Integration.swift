//
//  Integration.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Integration : XcodeServerEntity {
    
    //usually available during the whole integration's lifecycle
    public let queuedDate: NSDate
    public let shouldClean: Bool
    public let currentStep: Step!
    public let number: Int
    
    //usually available only after the integration has finished
    public let successStreak: Int?
    public let startedDate: NSDate?
    public let endedTime: NSDate?
    public let duration: NSTimeInterval?
    public let result: Result?
    public let buildResultSummary: BuildResultSummary?
    public let testedDevices: NSArray? //TODO: add typed array with parsing
    public let testHierarchy: NSArray? //TODO: add typed array with parsing
    public let assets: NSDictionary?  //TODO: add typed array with parsing
    
    public let blueprint: SourceControlBlueprint?
    
    public enum Step : String {
        case Unknown = ""
        case Pending = "pending"
        case Preparing = "preparing"
        case Checkout = "checkout"
        case Triggers = "triggers"
        case Building = "building"
        case Testing = "testing"
        case Archiving = "archiving"
        case Processing = "processing"
        case Uploading = "uploading"
        case Completed = "completed"
    }
    
    public enum Result : String {
        case Unknown = "unknown"
        case Succeeded = "succeeded"
        case BuildErrors = "build-errors"
        case TestFailures = "test-failures"
        case Warnings = "warnings"
        case AnalyzerWarnings = "analyzer-warnings"
        case BuildFailed = "build-failed"
        case CheckoutError = "checkout-error"
        case InternalError = "internal-error"
        case InternalCheckoutError = "internal-checkout-error"
        case InternalBuildError = "internal-build-error"
        case InternalProcessingError = "internal-processing-error"
        case Canceled = "canceled"
    }
    
    public required init(json: NSDictionary) {
        
        self.queuedDate = json.dateForKey("queuedDate")
        self.startedDate = json.optionalDateForKey("startedTime")
        self.endedTime = json.optionalDateForKey("endedTime")
        self.duration = json.optionalDoubleForKey("duration")
        self.shouldClean = json.boolForKey("shouldClean")
        self.currentStep = Step(rawValue: json.stringForKey("currentStep")) ?? .Unknown
        self.number = json.intForKey("number")
        self.successStreak = json.intForKey("success_streak")
        
        if let raw = json.optionalStringForKey("result") {
            self.result = Result(rawValue: raw)
        } else {
            self.result = nil
        }
        
        if let raw = json.optionalDictionaryForKey("buildResultSummary") {
            self.buildResultSummary = BuildResultSummary(json: raw)
        } else {
            self.buildResultSummary = nil
        }
        
        self.testedDevices = json.optionalArrayForKey("testedDevices")
        self.testHierarchy = json.optionalArrayForKey("testHierarchy")
        self.assets = json.optionalDictionaryForKey("assets")
        
        if let blueprint = json.optionalDictionaryForKey("revisionBlueprint") {
            self.blueprint = SourceControlBlueprint(json: blueprint)
        } else {
            self.blueprint = nil
        }
        
        super.init(json: json)
    }
}

public class BuildResultSummary : XcodeServerEntity {
    
    public let analyzerWarningCount: Int
    public let testFailureCount: Int
    public let testsChange: Int
    public let errorCount: Int
    public let testsCount: Int
    public let testFailureChange: Int
    public let warningChange: Int
    public let regressedPerfTestCount: Int
    public let warningCount: Int
    public let errorChange: Int
    public let improvedPerfTestCount: Int
    public let analyzerWarningChange: Int
    
    public required init(json: NSDictionary) {
        
        self.analyzerWarningCount = json.intForKey("analyzerWarningCount")
        self.testFailureCount = json.intForKey("testFailureCount")
        self.testsChange = json.intForKey("testsChange")
        self.errorCount = json.intForKey("errorCount")
        self.testsCount = json.intForKey("testsCount")
        self.testFailureChange = json.intForKey("testFailureChange")
        self.warningChange = json.intForKey("warningChange")
        self.regressedPerfTestCount = json.intForKey("regressedPerfTestCount")
        self.warningCount = json.intForKey("warningCount")
        self.errorChange = json.intForKey("errorChange")
        self.improvedPerfTestCount = json.intForKey("improvedPerfTestCount")
        self.analyzerWarningChange = json.intForKey("analyzerWarningChange")
        
        super.init(json: json)
    }
    
}

extension Integration : Hashable {
    
    public var hashValue: Int {
        get {
            return self.number
        }
    }
}

public func ==(lhs: Integration, rhs: Integration) -> Bool {
    return lhs.number == rhs.number
}


