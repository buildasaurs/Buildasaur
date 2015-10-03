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
    public let githubToken: String
    public let privateSSHKeyPath: String
    public let publicSSHKeyPath: String
    public let sshPassphrase: String?
    public let id: RefType
    
    public init(url: String, githubToken: String, privateSSHKeyPath: String, publicSSHKeyPath: String, sshPassphrase: String? = nil, id: RefType? = nil) {
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
    static let GitHubToken = "github_token"
    static let PrivateSSHKeyPath = "ssh_private_key_url"
    static let PublicSSHKeyPath = "ssh_public_key_url"
    static let SSHPassphrase = "ssh_passphrase"
    static let Id = "id"
}

extension ProjectConfig: JSONSerializable {
    
    public func jsonify() -> NSDictionary {
        
        let json = NSMutableDictionary()
        
        json[Keys.URL] = self.url
        json[Keys.GitHubToken] = self.githubToken
        json[Keys.PrivateSSHKeyPath] = self.privateSSHKeyPath
        json[Keys.PublicSSHKeyPath] = self.publicSSHKeyPath
        json[Keys.Id] = self.id
        json.optionallyAddValueForKey(self.sshPassphrase, key: "ssh_passphrase")
        return json
    }
    
    public init(json: NSDictionary) throws {
        
        self.url = try json.get(Keys.URL)
        self.githubToken = try json.get(Keys.GitHubToken)
        self.privateSSHKeyPath = try json.get(Keys.PrivateSSHKeyPath)
        self.publicSSHKeyPath = try json.get(Keys.PublicSSHKeyPath)
        self.id = try json.get(Keys.Id)
        self.sshPassphrase = try json.getOptionally(Keys.SSHPassphrase)
    }
}

