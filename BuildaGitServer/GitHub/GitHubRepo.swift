//
//  GitHubRepo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubRepo : GitHubEntity {
    
    let name: String
    let fullName: String
    let repoUrlHTTPS: String
    let repoUrlSSH: String
    let permissionsDict: NSDictionary
    
    var latestRateLimitInfo: RateLimitType?
    
    required init(json: NSDictionary) throws {

        self.name = json.stringForKey("name")
        self.fullName = json.stringForKey("full_name")
        self.repoUrlHTTPS = json.stringForKey("clone_url")
        self.repoUrlSSH = json.stringForKey("ssh_url")
        
        if let permissions = json.optionalDictionaryForKey("permissions") {
            self.permissionsDict = permissions
        } else {
            self.permissionsDict = NSDictionary()
        }
        
        try super.init(json: json)
    }
}

extension GitHubRepo: RepoType {
    
    var permissions: RepoPermissions {
        
        let read = self.permissionsDict["pull"] as? Bool ?? false
        let write = self.permissionsDict["push"] as? Bool ?? false
        return RepoPermissions(read: read, write: write)
    }
    
    var originUrlSSH: String {
        
        return self.repoUrlSSH
    }
}
