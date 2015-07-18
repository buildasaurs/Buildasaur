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
    
//    func DISABLED_testVerificationFailsWithEmptyKeys() {
//        
//        let blueprint: NSDictionary = [
//            "DVTSourceControlWorkspaceBlueprintLocationsKey":
//                ["1C5C2A17EEADA6DBF6678501245487A71FBE28BB": [
//                    "DVTSourceControlBranchIdentifierKey":"",
//                    "DVTSourceControlBranchOptionsKey":156,
//                    "DVTSourceControlWorkspaceBlueprintLocationTypeKey":"DVTSourceControlBranch"
//                    ]
//            ],
//            "DVTSourceControlWorkspaceBlueprintPrimaryRemoteRepositoryKey":"1C5C2A17EEADA6DBF6678501245487A71FBE28BB",
//            "DVTSourceControlWorkspaceBlueprintRemoteRepositoryAuthenticationStrategiesKey":[
//                "1C5C2A17EEADA6DBF6678501245487A71FBE28BB":[
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryPasswordKey":"",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryUsernameKey":"git",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryPublicKeyDataKey":"",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryAuthenticationTypeKey":
//                    "DVTSourceControlSSHKeysAuthenticationStrategy",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryAuthenticationStrategiesKey":""
//                ]
//            ],
//            "DVTSourceControlWorkspaceBlueprintWorkingCopyStatesKey": [
//                "1C5C2A17EEADA6DBF6678501245487A71FBE28BB":0],
//            "DVTSourceControlWorkspaceBlueprintIdentifierKey":"BD8CA0AA-2232-4E6D-9042-7630A1F3BFF8",
//            "DVTSourceControlWorkspaceBlueprintWorkingCopyPathsKey":[
//                "1C5C2A17EEADA6DBF6678501245487A71FBE28BB":"/"
//            ],
//            "DVTSourceControlWorkspaceBlueprintNameKey":"",
//            "DVTSourceControlWorkspaceBlueprintVersion":203,
//            "DVTSourceControlWorkspaceBlueprintRelativePathToProjectKey":"",
//            "DVTSourceControlWorkspaceBlueprintRemoteRepositoriesKey":[
//                [
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositorySystemKey":"com.apple.dt.Xcode.sourcecontrol.Git",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryIdentifierKey":
//                    "1C5C2A17EEADA6DBF6678501245487A71FBE28BB",
//                    "DVTSourceControlWorkspaceBlueprintRemoteRepositoryURLKey":"git@github.com:czechboy0/Buildasaur.git"
//                ]
//            ]
//        ]
//        let r = SSHKeyVerification.verifyBlueprint(blueprint)
//        XCTAssertEqual(r.terminationStatus, 1)
//        XCTAssertEqual(r.standardOutput, "")
//        XCTAssertEqual(r.standardError, "Failed to authenticate SSH session: Unable to allocate memory for public key data (-1)")
//    }
    
}
