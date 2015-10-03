//
//  ProjectConfig.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public struct ProjectConfig {
    
    public let url: String
    public let githubToken: String?
    public let privateSSHKeyPath: String?
    public let publicSSHKeyPath: String?
    public let sshPassphrase: String?
    public let id: RefType
    
    public init(url: String, githubToken: String? = nil, privateSSHKeyPath: String? = nil, publicSSHKeyPath: String? = nil, sshPassphrase: String? = nil, id: RefType? = nil) {
        self.url = url
        self.githubToken = githubToken
        self.privateSSHKeyPath = privateSSHKeyPath
        self.publicSSHKeyPath = publicSSHKeyPath
        self.sshPassphrase = sshPassphrase
        self.id = id ?? Ref.new()
    }
    
    public func validate() throws {
        //TODO: throw of required keys are not valid
    }
}

private struct Keys {
    
    static let URL = "url"
    static let ProjectRef = "project_ref"
    static let ServerRef = "server_ref"
    
    static let PostStatusComments = "post_status_comments"
    static let SyncInterval = "sync_interval"
    static let WaitForLttm = "wait_for_lttm"
    static let WatchedBranches = "watched_branches"
}

