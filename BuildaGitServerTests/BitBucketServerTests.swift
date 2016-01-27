//
//  BitBucketServerTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Cocoa
import XCTest
@testable import BuildaGitServer
import BuildaUtils
import DVR

class BitBucketServerTests: XCTestCase {

    var bitbucket: SourceServerType!
    
    override func setUp() {
        super.setUp()
        
        let session = DVR.Session
        self.bitbucket = GitServerFactory.server(.BitBucket, auth: nil)
    }
    
    override func tearDown() {
        
        self.bitbucket = nil
        
        super.tearDown()
    }
    
    func testLiveGetPullRequests() {
        
        let expect = self.expectationWithDescription("Waiting for url request")
        
        self.bitbucket.getOpenPullRequests("honzadvorsky/buildasaur-tester") { (prs, error) -> () in
            
            print(prs)
            print(error)
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
