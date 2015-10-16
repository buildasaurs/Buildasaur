//
//  Repo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class Repo : GitHubEntity {
    
    let name: String
    let fullName: String
    let repoUrlHTTPS: String
    let repoUrlSSH: String
    let permissions: NSDictionary
    
    required init(json: NSDictionary) {

        self.name = json.stringForKey("name")
        self.fullName = json.stringForKey("full_name")
        self.repoUrlHTTPS = json.stringForKey("clone_url")
        self.repoUrlSSH = json.stringForKey("ssh_url")
        
        if let permissions = json.optionalDictionaryForKey("permissions") {
            self.permissions = permissions
        } else {
            self.permissions = NSDictionary()
        }
        
        super.init(json: json)
    }
}
