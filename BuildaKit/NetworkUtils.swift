//
//  NetworkUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import BuildaUtils
import XcodeServerSDK

public class NetworkUtils {
    
    public class func checkAvailabilityOfGitHubWithCurrentSettingsOfProject(project: Project, completion: (success: Bool, error: ErrorType?) -> ()) {
        
        let token = project.config.value.githubToken
        //TODO: have project spit out Set<SourceServerOption>
        
        let options: Set<SourceServerOption> = [.Token(token)]
        let server: SourceServerType = SourceServerFactory().createServer(options)

        let credentialValidationBlueprint = project.createSourceControlBlueprintForCredentialVerification()
        
        //check if we can get PRs, that should be representative enough
        if let repoName = project.githubRepoName() {
            
            //we have a repo name
            server.getRepo(repoName, completion: { (repo, error) -> () in
                
                if error != nil {
                    completion(success: false, error: error)
                    return
                }
                
                if let repo = repo {

                    let permissions = repo.permissions
                    let readPermission = permissions.read
                    let writePermission = permissions.write
                    
                    //look at the permissions in the PR metadata
                    if !readPermission {
                        completion(success: false, error: Error.withInfo("Missing read permission for repo"))
                    } else if !writePermission {
                        completion(success: false, error: Error.withInfo("Missing write permission for repo"))
                    } else {
                        //now test ssh keys
                        //TODO: do SSH Key validation properly in the new UI once we have Xcode Server credentials.
                        self.checkValidityOfSSHKeys(credentialValidationBlueprint, completion: { (success, error) -> () in
                            
                            if success {
                                Log.verbose("Finished blueprint validation with success!")
                            } else {
                                Log.verbose("Finished blueprint validation with error: \(error)")
                            }
                        
                            //now complete
                            completion(success: success, error: error)
                        })
                    }
                } else {
                    completion(success: false, error: Error.withInfo("Couldn't find repo permissions in GitHub response"))
                }
            })
            
        } else {
            completion(success: false, error: Error.withInfo("Invalid repo name"))
        }
    }
    
    public class func checkAvailabilityOfXcodeServerWithCurrentSettings(config: XcodeServerConfig, completion: (success: Bool, error: NSError?) -> ()) {
        
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
            completion(success: false, error: Error.withInfo(r.standardError))
        }
    }
}
