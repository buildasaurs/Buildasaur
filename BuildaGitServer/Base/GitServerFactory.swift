//
//  GitServerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

class GitServerFactory {
    
    class func server(service: GitService, auth: ProjectAuthenticator?, http: HTTP? = nil) -> SourceServerType {

        let server: SourceServerType
        
        switch service {
        case .GitHub:
            let baseURL = "https://api.github.com"
            let endpoints = GitHubEndpoints(baseURL: baseURL, auth: auth)
            server = GitHubServer(endpoints: endpoints, http: http)
        case .BitBucket:
            let baseURL = "https://api.bitbucket.org"
            let endpoints = BitBucketEndpoints(baseURL: baseURL, auth: auth)
            server = BitBucketServer(endpoints: endpoints, http: http)
        case .GitLab:
            let baseURL = "https://gitlab.com/api/v3"
            fatalError("GitLab server not yet implemented")
        }
        
        return server
    }
    
}
