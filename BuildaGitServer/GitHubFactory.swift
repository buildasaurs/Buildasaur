//
//  GitHubFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class GitHubFactory {
    
    public class func server() -> GitHubServer {
     
        //TODO: pull from config
        let baseURL = "https://api.github.com"
        let token = "0efd98dda020c84d7a647f09f4fcfa10b6782c0a"
        
        let endpoints = GitHubEndpoints(baseURL: baseURL, token: token)
        
        let server = GitHubServer(endpoints: endpoints)
        return server
    }
    
}
