//
//  BuildaAnalyticsEvents.swift
//  Buildasaur
//
//  Created by Wyatt McBain on 8/24/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

extension String {
    
    /**
        Ensures that strings are appropriately formatted for analytics.
        Analytics event strings should be lower case and hyphenated.

        :returns: The formatted analytics String.
    */
    func toAnalyticsString() -> String {
        return self.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "-")
    }
}

/**
    The AnalyticsFunnel enumeration defines various funnels that the user
    initiates while using Buildasaur. Having funnel definitions allows us
    to break up analytics events into logical groups.

    - Xcode:                    Xcode Server Funnel
    - Github:                   Github Funnel
    - Feature:                  Application Features
    - Other(funnel: String):    Other Funnel - Pass String to define.
*/
public enum AnalyticsFunnel {
    case Xcode, Github, Feature, Other(funnel: String)
    
    public var funnelString: String {
        switch self {
        case .Xcode:
            return "xcode-integration"
        case .Github:
            return "github-integration"
        case .Feature:
            return "buildasaur-feature"
        case Other(let funnel):
            return funnel.toAnalyticsString()
        }
    }
}

/**
    The AnalyticsEvent protocol defines variables and functions
    that Analytics Event enumerations must implement.
*/
public protocol AnalyticsEvent {
    
    /**
        Retrieves the analytics string for a enumeration.
    */
    var analyticsString: String { get }
}

/**
    The XcodeAnalyticsEvent enumeration defines various Xcode events
    that we track as part of our Analytics package. Should be used when the
    analytics funnel definition is .Xcode.

    - BotCreation:              Bot was created
    - Other(event: String):     Other event - Pass String to define.
*/
public enum XcodeAnalyticsEvent: AnalyticsEvent {
    case BotCreation, Other(event: String)
    
    public var analyticsString: String {
        switch self {
        case .BotCreation:
            return "bot-creation"
        case Other(let event):
            return event.toAnalyticsString()
        }
    }
}

/**
    The GithubAnalyticsEvent enumeration defines various Github events
    that we track as part of our analytics package. Should be used when the
    analytics funnel definition is .Github.

    - PullRequest:              Pull request event
    - Other(event: String):     Other event - Pass String to define.
*/
public enum GithubAnalyticsEvent: AnalyticsEvent {
    case PullRequest, Other(event: String)
    
    public var analyticsString: String {
        switch self {
        case .PullRequest:
            return "pull-request"
        case .Other(let event):
            return event.toAnalyticsString()
        }
    }
}

/**
    The FeatureAnalyticsEvent enumeration defines various Buildasaur Feature events
    that we track as part of our analytics package. Should be used when the
    analytics funnel definition is .Feature.

    - OpenApp:                  Application is opened.
    - Other(event: String):     Other event - Pass String to define.
*/
public enum FeatureAnalyticsEvent: AnalyticsEvent {
    case OpenApp, Other(event: String)
    
    public var analyticsString: String {
        switch self {
        case .OpenApp:
            return "open-application"
        case .Other(let event):
            return event.toAnalyticsString()
        }
    }
}
