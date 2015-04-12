//
//  GitHubSource.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class GitHubServer : GitServer {
    
    public let endpoints: GitHubEndpoints
    
    public init(endpoints: GitHubEndpoints) {
        
        self.endpoints = endpoints
        super.init()
    }
    
    

}

extension GitHubServer {
    
    //add endpoint behaviors
    
//    public func getUser(completion: ())
    
}
