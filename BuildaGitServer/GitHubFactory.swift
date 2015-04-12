//
//  GitHubFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class GitHubFactory {
    
    public class func server(token: String?) -> GitHubServer {
     
        let baseURL = "https://api.github.com"
        let endpoints = GitHubEndpoints(baseURL: baseURL, token: token)
        
        let server = GitHubServer(endpoints: endpoints)
        return server
    }
    
}
