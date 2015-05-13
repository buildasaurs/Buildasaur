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
        let credentialValidationBlueprint = project.createSourceControlBlueprintForCredentialVerification()
        
        //check if we can get PRs, that should be representative enough
        if let repoName = project.githubRepoName() {
            
            //we have a repo name
            server.getRepo(repoName, completion: { (repo, error) -> () in
                
                if error != nil {
                    completion(success: false, error: error)
                    return
                }
                
                if
                    let repo = repo,
                    let readPermission = repo.permissions["pull"] as? Bool,
                    let writePermission = repo.permissions["push"] as? Bool
                {

                    //look at the permissions in the PR metadata
                    if !readPermission {
                        completion(success: false, error: Errors.errorWithInfo("Missing read permission for repo"))
                    } else if !writePermission {
                        completion(success: false, error: Errors.errorWithInfo("Missing write permission for repo"))
                    } else {
                        //now test ssh keys
                        self.checkValidityOfSSHKeys(credentialValidationBlueprint, completion: { (success, error) -> () in
                            
                            Log.verbose("Finished blueprint validation with success: \(success), error: \(error)")
                            
                            //now complete
                            completion(success: success, error: error)
                        })
                    }
                } else {
                    completion(success: false, error: Errors.errorWithInfo("Couldn't find repo permissions in GitHub response"))
                }
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
    
    class func checkValidityOfSSHKeys(blueprint: SourceControlBlueprint, completion: (success: Bool, error: NSError?) -> ()) {
        
        let blueprintDict = blueprint.dictionarify()
        let r = SSHKeyVerification.verifyBlueprint(blueprintDict)
        
        //based on the return value, either succeed or fail
        if r.terminationStatus == 0 {
            completion(success: true, error: nil)
        } else {
            completion(success: false, error: Errors.errorWithInfo(r.standardError))
        }
    }
}
