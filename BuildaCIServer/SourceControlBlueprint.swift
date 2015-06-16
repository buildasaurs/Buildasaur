//
//  SourceControlBlueprint.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 11/01/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

extension String {
    public var base64Encoded: String? {
        let data = dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        return data?.base64EncodedStringWithOptions(nil)
    }
}

public class SourceControlBlueprint : XcodeServerEntity {
    
    public let branch: String
    public let projectWCCIdentifier: String
    public let wCCName: String
    public let projectName: String
    public let projectURL: String
    public let projectPath: String
    public let commitSHA: String?
    public let privateSSHKey: String?
    public let publicSSHKey: String?
    public let sshPassphrase: String?
    
    public required init(json: NSDictionary) {
        
        self.wCCName = json.stringForKey(XcodeBlueprintNameKey)
        
        let primaryRepoId = json.stringForKey(XcodeBlueprintPrimaryRemoteRepositoryKey)
        self.projectWCCIdentifier = primaryRepoId

        let workingCopyPaths = json.dictionaryForKey(XcodeBlueprintWorkingCopyPathsKey)
        self.projectName = workingCopyPaths.stringForKey(primaryRepoId)

        let repos: [NSDictionary] = json.arrayForKey(XcodeBlueprintRemoteRepositoriesKey)
        let primarys: [NSDictionary] = repos.filter {
            (item: NSDictionary) -> Bool in
            return item.stringForKey(XcodeBlueprintRemoteRepositoryIdentifierKey) == primaryRepoId
        }
        
        self.projectPath = json.stringForKey(XcodeBlueprintRelativePathToProjectKey)

        let repo = primarys.first!
        self.projectURL = repo.stringForKey(XcodeBlueprintRemoteRepositoryURLKey)
        
        let locations = json.dictionaryForKey(XcodeBlueprintLocationsKey)
        let location = locations.dictionaryForKey(primaryRepoId)
        self.branch = location.optionalStringForKey(XcodeBranchIdentifierKey) ?? ""
        self.commitSHA = location.optionalStringForKey(XcodeLocationRevisionKey)
        
        self.privateSSHKey = nil
        self.publicSSHKey = nil
        self.sshPassphrase = nil
        
        super.init(json: json)
    }
    
    public init(branch: String, projectWCCIdentifier: String, wCCName: String, projectName: String,
        projectURL: String, projectPath: String, publicSSHKey: String?, privateSSHKey: String?, sshPassphrase: String?)
    {
        self.branch = branch
        self.projectWCCIdentifier = projectWCCIdentifier
        self.wCCName = wCCName
        self.projectName = projectName
        self.projectURL = projectURL
        self.projectPath = projectPath
        self.commitSHA = nil
        self.publicSSHKey = publicSSHKey
        self.privateSSHKey = privateSSHKey
        self.sshPassphrase = sshPassphrase
        
        super.init()
    }
    
    //for credentials verification only
    public convenience init(projectWCCIdentifier: String, projectURL: String, publicSSHKey: String?, privateSSHKey: String?, sshPassphrase: String?) {
        
        self.init(branch: "", projectWCCIdentifier: projectWCCIdentifier, wCCName: "", projectName: "", projectURL: projectURL, projectPath: "", publicSSHKey: publicSSHKey, privateSSHKey: privateSSHKey, sshPassphrase: sshPassphrase)
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dictionary = NSMutableDictionary()
        
        let repoId = self.projectWCCIdentifier
        let remoteUrl = self.projectURL
        var workingCopyPath = self.projectName
        //ensure a trailing slash
        if !workingCopyPath.hasSuffix("/") {
            workingCopyPath = workingCopyPath + "/"
        }
        let relativePathToProject = self.projectPath
        let blueprintName = self.wCCName
        let branch = self.branch
        let sshPublicKey = self.publicSSHKey?.base64Encoded ?? ""
        let sshPrivateKey = self.privateSSHKey?.base64Encoded ?? ""
        let sshPassphrase = self.sshPassphrase ?? ""
        
        //locations on the branch
        dictionary[XcodeBlueprintLocationsKey] = [
            repoId: [
                XcodeBranchIdentifierKey: branch,
                XcodeBranchOptionsKey: 156, //super magic number
                XcodeBlueprintLocationTypeKey: "DVTSourceControlBranch" //TODO: add more types?
            ]
        ]

        //primary remote repo
        dictionary[XcodeBlueprintPrimaryRemoteRepositoryKey] = repoId
        
        //working copy states?
        dictionary[XcodeBlueprintWorkingCopyStatesKey] = [
            repoId: 0
        ]
        
        //blueprint identifier
        dictionary[XcodeBlueprintIdentifierKey] = NSUUID().UUIDString
        
        //all remote repos
        dictionary[XcodeBlueprintRemoteRepositoriesKey] = [
            [
                XcodeBlueprintRemoteRepositoryURLKey: remoteUrl,
                XcodeBlueprintRemoteRepositorySystemKey: "com.apple.dt.Xcode.sourcecontrol.Git", //TODO: add more SCMs
                XcodeBlueprintRemoteRepositoryIdentifierKey: repoId
            ]
        ]
        
        //working copy paths
        dictionary[XcodeBlueprintWorkingCopyPathsKey] = [
            repoId: workingCopyPath
        ]
        
        //blueprint name
        dictionary[XcodeBlueprintNameKey] = blueprintName
        
        //blueprint version
        dictionary[XcodeBlueprintVersion] = 203 //magic number again
        
        //path from working copy to project
        dictionary[XcodeBlueprintRelativePathToProjectKey] = relativePathToProject
        
        //repo authentication
        dictionary[XcodeRepositoryAuthenticationStrategiesKey] = [
            repoId: [
                XcodeRepoAuthenticationTypeKey: XcodeRepoSSHKeysAuthenticationStrategy,
                XcodeRepoUsernameKey: "git", //TODO: see how to add https support?
                XcodeRepoPasswordKey: sshPassphrase, //this is where the passphrase goes
                XcodeRepoAuthenticationStrategiesKey: sshPrivateKey,
                XcodeRepoPublicKeyDataKey: sshPublicKey
            ]
        ]
        
        return dictionary

    }
}

