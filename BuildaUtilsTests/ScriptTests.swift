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
    
    func testGitVersion() {
        
        //here we have to specify the exact path, unfortunately `which git` leads to the prebundled git in xcode
        //whereas when you run Buildasaur normally (under your user), `which git` will do what you'd expect, choose
        //your active git binary (probably in /usr/bin/git or /usr/local/bin/git
        
        let response = Script.run("/usr/bin/git", arguments: ["--version"])
        XCTAssertEqual(response.terminationStatus, 0)
        XCTAssertEqual(response.standardError, "")
        
        let versionString = response.standardOutput
        XCTAssert(count(versionString) > 0, "Git version must not be an empty string")
        
        let comps = versionString.componentsSeparatedByString(" ")
        XCTAssertGreaterThanOrEqual(comps.count, 3)
        
        if comps.count >= 3 {
            let version = comps[2]
            XCTAssertGreaterThanOrEqual(version, "2.3.0", "Git version must be at least 2.3")            
        }
    }
    
    func testWhich() {
        
        let response = Script.run("which", arguments: ["which"])
        let expectedWhichPath = "/usr/bin/which"
        let r = response.standardOutput.stripTrailingNewline()
        XCTAssertEqual(r, expectedWhichPath, "Which is assumed to be in \(expectedWhichPath)")
    }
    
    func testBuildasaurReachabilityWithGit() {
        
        let response = Script.run("/usr/bin/git", arguments: ["ls-remote", "git@github.com:czechboy0/Buildasaur.git"])
        let r = response.standardOutput
        XCTAssertEqual(response.terminationStatus, 0)
        XCTAssertEqual(response.standardError, "")
        XCTAssert(count(r) > 0, "Output must be nonempty")
    }
    
    func testUnknownReachabilityWithGit() {
        
        let response = Script.run("/usr/bin/git", arguments: ["ls-remote", "git@github.com:czechboy1/dummy.git"])
        let r = response.standardOutput
        XCTAssertEqual(response.terminationStatus, 128)
        XCTAssert(response.standardError.hasPrefix("ERROR"), "Error output should provide error")
        XCTAssertEqual(response.standardOutput, "", "Standard output should be empty")
    }
    
}
