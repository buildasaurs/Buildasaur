
//  GitHubServerTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa
import XCTest
import BuildaGitServer
import BuildaUtils

class GitHubSourceTests: XCTestCase {

    var github: GitHubServer!

    override func setUp() {
        super.setUp()

        self.github = GitHubFactory.server(nil)
    }
    
    override func tearDown() {
        
        self.github = nil
        
        super.tearDown()
    }

    func tryEndpoint(method: HTTP.Method, endpoint: GitHubEndpoints.Endpoint, params: [String: String]?, completion: (body: AnyObject!, error: NSError!) -> ()) {
        
        let expect = expectationWithDescription("Waiting for url request")
        
        let request = try! self.github.endpoints.createRequest(method, endpoint: endpoint, params: params)
        
        self.github.http.sendRequest(request, completion: { (response, body, error) -> () in
            
            completion(body: body, error: error)
            expect.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testGetPullRequests() {
        
        let params = [
            "repo": "czechboy0/Buildasaur-Tester"
        ]
        
        self.tryEndpoint(.GET, endpoint: .PullRequests, params: params) { (body, error) -> () in
            
            XCTAssertNotNil(body, "Body must be non-nil")
            if let body = body as? NSArray {
                let prs: [PullRequest] = GitHubArray(body)
                XCTAssertGreaterThan(prs.count, 0, "We need > 0 items to test parsing")
                Log.verbose("Parsed PRs: \(prs)")
            } else {
                XCTFail("Body nil")
            }
        }
    }
    
    func testGetBranches() {
        
        let params = [
            "repo": "czechboy0/Buildasaur-Tester"
        ]
        
        self.tryEndpoint(.GET, endpoint: .Branches, params: params) { (body, error) -> () in
            
            XCTAssertNotNil(body, "Body must be non-nil")
            if let body = body as? NSArray {
                let branches: [Branch] = GitHubArray(body)
                XCTAssertGreaterThan(branches.count, 0, "We need > 0 items to test parsing")
                Log.verbose("Parsed branches: \(branches)")
            } else {
                XCTFail("Body nil")
            }
        }
    }

    //manual parsing tested here, sort of a documentation as well
    
    func testUserParsing() {
        
        let dictionary = [
            "login": "czechboy0",
            "name": "Honza Dvorsky",
            "avatar_url": "https://avatars.githubusercontent.com/u/2182121?v=3",
            "html_url": "https://github.com/czechboy0"
        ]
        
        let user = User(json: dictionary)
        XCTAssertEqual(user.userName, "czechboy0")
        XCTAssertEqual(user.realName!, "Honza Dvorsky")
        XCTAssertEqual(user.avatarUrl!, "https://avatars.githubusercontent.com/u/2182121?v=3")
        XCTAssertEqual(user.htmlUrl!, "https://github.com/czechboy0")
    }
    
    func testRepoParsing() {
        
        let dictionary = [
            "name": "Buildasaur",
            "full_name": "czechboy0/Buildasaur",
            "clone_url": "https://github.com/czechboy0/Buildasaur.git",
            "ssh_url": "git@github.com:czechboy0/Buildasaur.git",
            "html_url": "https://github.com/czechboy0/Buildasaur"
        ]
        
        let repo = Repo(json: dictionary)
        XCTAssertEqual(repo.name, "Buildasaur")
        XCTAssertEqual(repo.fullName, "czechboy0/Buildasaur")
        XCTAssertEqual(repo.repoUrlHTTPS, "https://github.com/czechboy0/Buildasaur.git")
        XCTAssertEqual(repo.repoUrlSSH, "git@github.com:czechboy0/Buildasaur.git")
        XCTAssertEqual(repo.htmlUrl!, "https://github.com/czechboy0/Buildasaur")
    }
    
    func testCommitParsing() {
        
        let dictionary: NSDictionary = [
            "sha": "08182438ed2ef3b34bd97db85f39deb60e2dcd7d",
            "url": "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d"
        ]
        
        let commit = Commit(json: dictionary)
        XCTAssertEqual(commit.sha, "08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
        XCTAssertEqual(commit.url!, "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
    }

    func testBranchParsing() {
        
        let commitDictionary = [
            "sha": "08182438ed2ef3b34bd97db85f39deb60e2dcd7d",
            "url": "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d"
        ]
        let dictionary = [
            "name": "master",
            "commit": commitDictionary
        ]
        
        let branch = Branch(json: dictionary)
        XCTAssertEqual(branch.name, "master")
        XCTAssertEqual(branch.commit.sha, "08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
        XCTAssertEqual(branch.commit.url!, "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
    }
    
    func testPullRequestBranchParsing() {
        
        let dictionary = [
            "ref": "fb-loadNode",
            "sha": "7e45fa772565969ee801b0bdce0f560122e34610",
            "user": [
                "login": "aleclarson",
                "avatar_url": "https://avatars.githubusercontent.com/u/1925840?v=3",
                "url": "https://api.github.com/users/aleclarson",
                "html_url": "https://github.com/aleclarson",
            ],
            "repo": [
                "name": "AsyncDisplayKit",
                "full_name": "aleclarson/AsyncDisplayKit",
                "owner": [
                    "login": "aleclarson",
                    "avatar_url": "https://avatars.githubusercontent.com/u/1925840?v=3",
                    "url": "https://api.github.com/users/aleclarson",
                    "html_url": "https://github.com/aleclarson",
                ],
                "html_url": "https://github.com/aleclarson/AsyncDisplayKit",
                "description": "Smooth asynchronous user interfaces for iOS apps.",
                "url": "https://api.github.com/repos/aleclarson/AsyncDisplayKit",
                "ssh_url": "git@github.com:aleclarson/AsyncDisplayKit.git",
                "clone_url": "https://github.com/aleclarson/AsyncDisplayKit.git",
            ]
        ]
        
        let prbranch = PullRequestBranch(json: dictionary)
        XCTAssertEqual(prbranch.ref, "fb-loadNode")
        XCTAssertEqual(prbranch.sha, "7e45fa772565969ee801b0bdce0f560122e34610")
        XCTAssertEqual(prbranch.repo.name, "AsyncDisplayKit")
    }

    
    
    
}
