//
//  BuildaAnalyticsTests.swift
//  BuildaAnalyticsTests
//
//  Created by Wyatt McBain on 8/24/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import BuildaAnalytics

import Tapstream

class BuildaAnalyticsTests: XCTestCase {
    
    func testBuildaAnalyticsAlwaysReturnsOneInstance() {
        let buildaAnalyticsFirst    = BuildaAnalytics.sharedInstance
        let buildaAnalyticsSecond   = BuildaAnalytics.sharedInstance
        
        XCTAssertTrue(buildaAnalyticsFirst == buildaAnalyticsSecond, "Both analytics objects should be equal")
    }
    
    func testCreatingOtherEnumsGeneratesFormattedString() {
        let funnelOther = AnalyticsFunnel.Other(funnel: "some other funnel")
        let xcodeOther = XcodeAnalyticsEvent.Other(event: "some other xcode")
        let githubOther = GithubAnalyticsEvent.Other(event: "some other github")
        let featureOther = FeatureAnalyticsEvent.Other(event: "some other feature")
        
        XCTAssertTrue(funnelOther.funnelString == "some-other-funnel", "Expected: some-other-funnel")
        XCTAssertTrue(xcodeOther.analyticsString == "some-other-xcode", "Expected: some-other-xcode")
        XCTAssertTrue(githubOther.analyticsString == "some-other-github", "Expected: some-other-github")
        XCTAssertTrue(featureOther.analyticsString == "some-other-feature", "Expected: some-other-feature")
    }
}
