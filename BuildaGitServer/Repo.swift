//
//  Repo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Repo : GitHubEntity {
    
    public let name: String
    public let fullName: String
    public let repoUrlHTTPS: String
    public let repoUrlSSH: String
    public let permissions: NSDictionary
    
    public required init(json: NSDictionary) {

        self.name = json.stringForKey("name")
        self.fullName = json.stringForKey("full_name")
        self.repoUrlHTTPS = json.stringForKey("clone_url")
        self.repoUrlSSH = json.stringForKey("ssh_url")
        self.permissions = json.dictionaryForKey("permissions")
        
        super.init(json: json)
    }
}
