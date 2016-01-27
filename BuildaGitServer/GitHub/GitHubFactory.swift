//
//  GitHubFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

class GitHubFactory {
    
    class func server(auth: ProjectAuthenticator?) -> GitHubServer {
        
        let baseURL = "https://api.github.com"
        let endpoints = GitHubEndpoints(baseURL: baseURL, auth: auth)
        
        let server = GitHubServer(endpoints: endpoints)
        return server
    }
    
}
