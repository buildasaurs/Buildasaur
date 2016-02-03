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
    
    public typealias VerificationCompletion = (success: Bool, error: ErrorType?) -> ()
    
    public class func checkAvailabilityOfServiceWithProject(project: Project, completion: VerificationCompletion) {
        
        self.checkService(project, completion: { success, error in
            
            if !success {
                completion(success: false, error: error)
                return
            }
            
            //now test ssh keys
            let credentialValidationBlueprint = project.createSourceControlBlueprintForCredentialVerification()
            self.checkValidityOfSSHKeys(credentialValidationBlueprint, completion: { (success, error) -> () in
                
                if success {
                    Log.verbose("Finished blueprint validation with success!")
                } else {
                    Log.verbose("Finished blueprint validation with error: \(error)")
                }
                
                //now complete
                completion(success: success, error: error)
            })
        })
    }
    
    private class func checkService(project: Project, completion: VerificationCompletion) {
        
        let auth = project.config.value.serverAuthentication
        let service = auth!.service
        let server = SourceServerFactory().createServer(service, auth: auth)
        
        //check if we can get the repo and verify permissions
        guard let repoName = project.serviceRepoName() else {
            completion(success: false, error: Error.withInfo("Invalid repo name"))
            return
        }
        
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
                    //now complete
                    completion(success: true, error: nil)
                }
            } else {
                completion(success: false, error: Error.withInfo("Couldn't find repo permissions in \(service.prettyName()) response"))
            }
        })
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
