//
//  XcodeProject.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK

extension Project {
    
    public func createSourceControlBlueprint(branch: String) -> SourceControlBlueprint {
        
        let workspaceMetadata = self.workspaceMetadata!
        
        let projectWCCIdentifier = workspaceMetadata.projectWCCIdentifier
        let wccName = workspaceMetadata.projectWCCName
        let projectName = workspaceMetadata.projectName
        let projectURL = workspaceMetadata.projectURL.absoluteString
        let projectPath = workspaceMetadata.projectPath
        let publicSSHKey = self.publicSSHKey
        let privateSSHKey = self.privateSSHKey
        let sshPassphrase = self.config.sshPassphrase
        
        let blueprint = SourceControlBlueprint(branch: branch, projectWCCIdentifier: projectWCCIdentifier, wCCName: wccName, projectName: projectName, projectURL: projectURL, projectPath: projectPath, publicSSHKey: publicSSHKey, privateSSHKey: privateSSHKey, sshPassphrase: sshPassphrase)
        return blueprint
    }
    
    public func createSourceControlBlueprintForCredentialVerification() -> SourceControlBlueprint {
        
        let projectURL = self.workspaceMetadata!.projectURL.absoluteString
        let publicSSHKey = self.publicSSHKey
        let privateSSHKey = self.privateSSHKey
        let sshPassphrase = self.config.sshPassphrase
        
        let blueprint = SourceControlBlueprint(projectURL: projectURL, publicSSHKey: publicSSHKey, privateSSHKey: privateSSHKey, sshPassphrase: sshPassphrase)
        return blueprint
    }
}
