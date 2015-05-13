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
    
    func testRealGitVersion() {
        
        let response = SSHKeyVerification.getGitVersion()
        XCTAssertEqual(response.terminationStatus, 0)
        XCTAssertEqual(response.standardError, "")
        
        let (success, errorString) = SSHKeyVerification.verifyGitVersion(response)
        XCTAssertTrue(success)
        XCTAssertEqual(errorString, "")
    }
    
    func testFakeWrongGitVersion() {
        
        //test we catch lower versions...
        let response = (0, "git version 2.1.0 bla bla bla", "")
        
        let (success, errorString) = SSHKeyVerification.verifyGitVersion(response)
        XCTAssertFalse(success)
        XCTAssertNotEqual(errorString, "")
    }
    
    func testWhich() {
        
        let response = Script.run("which", arguments: ["which"])
        let expectedWhichPath = "/usr/bin/which"
        let r = response.standardOutput.stripTrailingNewline()
        XCTAssertEqual(r, expectedWhichPath, "Which is assumed to be in \(expectedWhichPath)")
    }
    
    //TODO: look into creating temp keys for test process, currently ssh-keygen fails for whatever reason when
    //ran as a test process but works from the command line. sigh.
//    func withTemporaryKeys(block: (keyPath: String) -> ()) {
//        
//        //create temp SSH keys
//        let temp = NSHomeDirectory().stringByAppendingPathComponent("mykeys")
//        let tempResp = Script.run("ssh-keygen", arguments: ["-t", "rsa", "-N", "" ,"-f", "\"\(temp)\""])
//        block(keyPath: temp)
//        NSFileManager.defaultManager().removeItemAtPath(temp, error: nil)
//    }
//    
//    func testBuildasaurReachabilityWithGit() {
//        
//        self.withTemporaryKeys { (keyPath: String) -> () in
//            
//            let r = SSHKeyVerification.verifyKeys(keyPath, repoSSHUrl: "git@github.com:czechboy0/Buildasaur.git")
//            let response = r.standardOutput
//            XCTAssertEqual(r.terminationStatus, 0)
//            XCTAssertEqual(r.standardError, "")
//            XCTAssert(count(response) > 0, "Output must be nonempty")
//        }
//    }
//    
//    func testUnknownReachabilityWithGit() {
//        
//        self.withTemporaryKeys { (keyPath: String) -> () in
//            
//            let response = SSHKeyVerification.verifyKeys(keyPath, repoSSHUrl: "git@github.com:czechboy0/dummy.git")
//            let r = response.standardOutput
//            XCTAssertEqual(response.terminationStatus, 128)
//            XCTAssert(response.standardError.hasPrefix("ERROR"), "Error output should provide error")
//            XCTAssertEqual(response.standardOutput, "", "Standard output should be empty")
//        }
//    }
    
}
