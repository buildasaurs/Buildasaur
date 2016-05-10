//
//  WorkspaceMetadataTests.swift
//  Buildasaur
//
//  Created by Isaac Overacker on 5/6/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
import Nimble
@testable import BuildaKit
import BuildaGitServer

class WorkspaceMetadataTests: XCTestCase {

    func help_test_parse_with(urlString url: String, expectedCheckoutType: CheckoutType, expectedGitService: GitService) {
        guard let (checkoutType, service) = WorkspaceMetadata.parse(url) else {
            XCTFail("Failed to parse URL string: \(url)")
            return
        }

        expect(checkoutType) == expectedCheckoutType
        expect(service) == expectedGitService
    }

    // MARK: GitHub

    func test_parse_SSH_withSlash_github() {
        help_test_parse_with(urlString: "ssh://git@github.com/organization/repo",
                             expectedCheckoutType: CheckoutType.SSH,
                             expectedGitService: GitService.GitHub)
    }

    func test_parse_noSSH_withColon_github() {
        help_test_parse_with(urlString: "git@github.com:organization/repo",
                             expectedCheckoutType: CheckoutType.SSH,
                             expectedGitService: GitService.GitHub)
    }

    // MARK: BitBucket

    func test_parse_SSH_withSlash_bitbucket() {
        help_test_parse_with(urlString: "ssh://git@bitbucket.org/organization/repo",
                             expectedCheckoutType: CheckoutType.SSH,
                             expectedGitService: GitService.BitBucket)
    }

    func test_parse_noSSH_withColon_bitbucket() {
        help_test_parse_with(urlString: "git@bitbucket.org:organization/repo",
                             expectedCheckoutType: CheckoutType.SSH,
                             expectedGitService: GitService.BitBucket)
    }

    // MARK: HTTP

    func test_parse_HTTPS() {
        expect(WorkspaceMetadata.parse("https://github.com/organization/repo")).to(beNil())
    }

    func test_parse_HTTP() {
        expect(WorkspaceMetadata.parse("http://github.com/organization/repo")).to(beNil())
    }

    func test_parse_implicitHTTP() {
        expect(WorkspaceMetadata.parse("github.com/organization/repo")).to(beNil())
    }

    // MARK: Git protocol

    func test_parse_git() {
        expect(WorkspaceMetadata.parse("git://github.com/organization/repo")).to(beNil())
    }
}
