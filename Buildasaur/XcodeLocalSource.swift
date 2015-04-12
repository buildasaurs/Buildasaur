//
//  XcodeLocalSource.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer

extension LocalSource {
    
    public func createSourceControlBlueprint(branch: String) -> SourceControlBlueprint {
        
        let projectWCCIdentifier = self.projectWCCIdentifier!
        let wccName = self.projectWCCName!
        let projectName = self.projectName!
        let projectURL = self.projectURL!.absoluteString!
        let projectPath = self.projectPath!
        let publicSSHKey = self.publicSSHKey
        let privateSSHKey = self.privateSSHKey
        
        let blueprint = SourceControlBlueprint(branch: branch, projectWCCIdentifier: projectWCCIdentifier, wCCName: wccName, projectName: projectName, projectURL: projectURL, projectPath: projectPath, publicSSHKey: publicSSHKey, privateSSHKey: privateSSHKey)
        return blueprint
    }
    
}
