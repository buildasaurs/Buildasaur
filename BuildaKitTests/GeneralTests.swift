//
//  GeneralTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/4/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import BuildaKit

class GeneralTests: XCTestCase {

    func testXcodeWorkspaceParsing() {
        
        let projectUrl = NSURL(fileURLWithPath: MockProject().config.value.url)
        let projects = try? XcodeProjectXMLParser.parseProjectsInsideOfWorkspace(projectUrl)
        XCTAssert(projects != nil)
        XCTAssert(projects?.count > 0)
    }


}
