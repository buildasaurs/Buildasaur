//
//  NetworkUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

class NetworkUtils {
    
    class func checkAvailabilityOfGitHubWithCurrentSettingsOfProject(project: LocalSource, completion: (success: Bool, error: NSError?) -> ()) {
        
        let token = project.githubToken
        let server = GitHubFactory.server(token)
        
        //check if we can get PRs, that should be representative enough
        if let repoName = project.githubRepoName() {
            
            //we have a repo name
            server.getOpenPullRequests(repoName, completion: { (prs, error) -> () in
                
                if error != nil {
                    completion(success: false, error: error)
                    return
                }
                
                //seems like we got PRs!
                completion(success: true, error: nil)
            })
            
        } else {
            completion(success: false, error: Errors.errorWithInfo("Invalid repo name"))
        }
    }
    
    class func checkAvailabilityOfXcodeServerWithCurrentSettings(config: XcodeServerConfig, completion: (success: Bool, error: NSError?) -> ()) {
        
        let xcodeServer = XcodeServerFactory.server(config)
        
        //the way we check availability is first by logging out (does nothing if not logged in) and then
        //calling getUserCanCreateBots, which, if necessary, authenticates before resolving to true or false in JSON.
        xcodeServer.logout { (success, error) -> () in
            
            if let error = error {
                completion(success: false, error: error)
                return
            }
            
            xcodeServer.getUserCanCreateBots({ (canCreateBots, error) -> () in
                
                if let error = error {
                    completion(success: false, error: error)
                    return
                }
                
                completion(success: canCreateBots, error: nil)
            })
        }
    }
}
