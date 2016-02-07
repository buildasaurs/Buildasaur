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
    
    func testGetRepo() {
        
        self.prepServerWithName("bitbucket_get_repo")
        
        let exp = self.expectationWithDescription("Waiting for url request")
        
        self.bitbucket.getRepo("honzadvorsky/buildasaur-tester") { (repo, error) -> () in
            
            expect(error).to(beNil())
            guard let repo = repo else { fail(); return }
            
            expect(repo.originUrlSSH) == "git@bitbucket.org:honzadvorsky/buildasaur-tester.git"
            
            exp.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testGetComments() {
        
        self.prepServerWithName("bitbucket_get_comments")
        
        let exp = self.expectationWithDescription("Waiting for url request")
        
        self.bitbucket.getCommentsOfIssue(4, repo: "honzadvorsky/buildasaur-tester") { (comments, error) -> () in
            
            expect(error).to(beNil())
            guard let comments: [CommentType] = comments else { fail(); return }
            
            expect(comments.count) == 2
            let c1 = comments[0].body
            let c2 = comments[1].body
            expect(c1) == "Another **hello world**"
            expect(c2) == "Hello world"
            
            exp.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testPostStatus() {
        
        self.prepServerWithName("bitbucket_post_status")
        
        let exp = self.expectationWithDescription("Waiting for url request")
        
        let status = self.bitbucket.createStatusFromState(BuildState.Success, description: "All went great!", targetUrl: "https://stlt.herokuapp.com/v1/xcs_deeplink/honzadvysmbpr14.home/1413f8578e54c3d052b8121a250255c0/1413f8578e54c3d052b8121a2509a923")
        
        self.bitbucket.postStatusOfCommit("787ce95", status: status, repo: "honzadvorsky/buildasaur-tester") { (status, error) -> () in
            
            expect(error).to(beNil())
            guard let status = status else { fail(); return }
            
            expect(status.description) == "All went great!"
            expect(status.state) == BuildState.Success
            expect(status.targetUrl) == "https://stlt.herokuapp.com/v1/xcs_deeplink/honzadvysmbpr14.home/1413f8578e54c3d052b8121a250255c0/1413f8578e54c3d052b8121a2509a923"
            
            exp.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testGetStatus() {
        
        self.prepServerWithName("bitbucket_get_status")
        
        let exp = self.expectationWithDescription("Waiting for url request")
        
        self.bitbucket.getStatusOfCommit("787ce95", repo: "honzadvorsky/buildasaur-tester") { (status, error) -> () in
            
            expect(error).to(beNil())
            guard let status = status else { fail(); return }
            
            expect(status.description) == "All went great!"
            expect(status.state) == BuildState.Success
            expect(status.targetUrl) == "https://stlt.herokuapp.com/v1/xcs_deeplink/honzadvysmbpr14.home/1413f8578e54c3d052b8121a250255c0/1413f8578e54c3d052b8121a2509a923"
            
            exp.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    //    func testPostComment() {
    //        //TODO:
    //    }
    
    //    func testGetBranches() {
    //        //TODO:
    //    }
    
}
