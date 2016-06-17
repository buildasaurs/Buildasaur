//
//  AuthenticationTests.swift
//  Buildasaur
//
//  Created by Rachel Caileff on 3/14/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import BuildaGitServer

class AuthenticationTests: XCTestCase {

    let gitService = "GIT"
    let tokenType = "PersonalToken"
    let tokenValue = "1234567890"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmptyStringShouldThrow() {
        do {
            try ProjectAuthenticator.fromString("")
            XCTFail()
        } catch {
            // Expected behavior
        }
    }

    func testInvalidHostShouldThrow() {
        do {
            try ProjectAuthenticator.fromString("a:\(gitService):\(tokenType):\(tokenValue)")
            XCTFail()
        } catch {
            // Expected behavior
        }
    }

    func testNonexistantHostShouldThrow() {
        do {
            try ProjectAuthenticator.fromString("some.fakehostname.com:\(gitService):\(tokenType):\(tokenValue)")
            XCTFail()
        } catch {
            // Expected behavior
        }
    }

    func testInvalidAuthTypeShouldThrow() {
        do {
            try ProjectAuthenticator.fromString("\(GitService.GitHub.hostname()):\(gitService):junkstring:\(tokenValue)")
            XCTFail()
        } catch {
            // Expected behavior
        }
    }

    func testValidStringShouldNotThrow() {
        do {
            try ProjectAuthenticator.fromString("\(GitService.GitHub.hostname()):\(gitService):\(tokenType):\(tokenValue)")
        } catch {
            XCTFail()
        }
    }
}
