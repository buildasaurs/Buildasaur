//
//  ScriptTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XCTest
import BuildaUtils

class ScriptTests: XCTestCase {
    
    func testWhich() {
        
        let response = Script.run("which", arguments: ["which"])
        let expectedWhichPath = "/usr/bin/which"
        let r = response.standardOutput.stripTrailingNewline()
        XCTAssertEqual(r, expectedWhichPath, "Which is assumed to be in \(expectedWhichPath)")
    }
    
    func testHelloWorld() {
        
        let response = Script.run("echo", arguments: ["hello world"])
        let expectedWhichPath = "hello world"
        let r = response.standardOutput.stripTrailingNewline()
        XCTAssertEqual(r, expectedWhichPath)
    }
}
