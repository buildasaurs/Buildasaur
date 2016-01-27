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
import Nimble

class BitBucketServerTests: XCTestCase {

    var bitbucket: SourceServerType!
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        self.bitbucket = nil
        
        super.tearDown()
    }
    
    func prepServerWithName(name: String) {
        
        let session = DVR.Session(cassetteName: name, testBundle: NSBundle(forClass: self.classForCoder))
        let http = HTTP(session: session)
        self.bitbucket = GitServerFactory.server(.BitBucket, auth: nil, http: http)
    }
    
    func testGetPullRequests() {
        
        self.prepServerWithName("bitbucket_get_prs")
        
        let exp = self.expectationWithDescription("Waiting for url request")
        
        self.bitbucket.getOpenPullRequests("honzadvorsky/buildasaur-tester") { (prs, error) -> () in
            
            expect(error).to(beNil())
            guard let prs = prs else { fail(); return }
            
            expect(prs.count) == 4
            
            let pr = prs.first!
            expect(pr.title) == "README.md edited online with Bitbucket"
            expect(pr.number) == 4
            expect(pr.baseName) == "czechboy0-patch-6"
            expect(pr.headCommitSHA) == "787ce956a784"
            expect(pr.headName) == "honzadvorsky/readmemd-edited-online-with-bitbucket-1453476305123"
            expect(pr.headRepo.originUrlSSH) == "git@bitbucket.org:honzadvorsky/buildasaur-tester.git"
            
            exp.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
