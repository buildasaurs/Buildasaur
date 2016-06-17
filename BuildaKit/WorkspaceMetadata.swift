//
//  WorkspaceMetadata.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 29/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import BuildaGitServer

public enum CheckoutType: String {
    case SSH = "SSH"
    //        case HTTPS - not yet supported, right now only SSH is supported
    //        (for bots reasons, will be built in when I have time)
    //        case SVN - not yet supported yet
}

public struct WorkspaceMetadata {
    
    public let projectName: String
    public let projectPath: String
    public let projectWCCIdentifier: String
    public let projectWCCName: String
    public let projectURL: NSURL
    public let service: GitService
    public let checkoutType: CheckoutType
    
    init(projectName: String?, projectPath: String?, projectWCCIdentifier: String?, projectWCCName: String?, projectURLString: String?) throws {
        
        let errorForMissingKey: (String) -> ErrorType = { Error.withInfo("Can't find/parse \"\($0)\" in workspace metadata!") }
        guard let projectName = projectName else { throw errorForMissingKey("Project Name") }
        guard let projectPath = projectPath else { throw errorForMissingKey("Project Path") }
        guard let projectWCCIdentifier = projectWCCIdentifier else { throw errorForMissingKey("Project WCC Identifier") }
        guard let projectWCCName = projectWCCName else { throw errorForMissingKey("Project WCC Name") }
        guard let projectURLString = projectURLString else { throw errorForMissingKey("Project URL") }
        guard let (checkoutType, service) = WorkspaceMetadata.parse(projectURLString) else {
            let allowedString = [CheckoutType.SSH].map({ $0.rawValue }).joinWithSeparator(", ")
            let error = Error.withInfo("Disallowed checkout type, the project must be checked out over one of the supported schemes: \(allowedString)")
            throw error
        }
        
        //we have to prefix SSH urls with "git@" (for a reason I don't remember anymore, probs because the user "git" is treated as a standard part of the url itself)
        var correctedProjectUrlString = projectURLString
        if case .SSH = checkoutType where !projectURLString.hasPrefix("git@") {
            correctedProjectUrlString = "git@" + projectURLString
        }
        
        guard let projectURL = NSURL(string: correctedProjectUrlString) else { throw Error.withInfo("Can't parse url \"\(projectURLString)\"") }
        
        self.projectName = projectName
        self.projectPath = projectPath
        self.projectWCCIdentifier = projectWCCIdentifier
        self.projectWCCName = projectWCCName
        self.projectURL = projectURL
        self.checkoutType = checkoutType
        self.service = service
    }
    
    func duplicateWithForkURL(forkUrlString: String?) throws -> WorkspaceMetadata {
        return try WorkspaceMetadata(projectName: self.projectName, projectPath: self.projectPath, projectWCCIdentifier: self.projectWCCIdentifier, projectWCCName: self.projectWCCName, projectURLString: forkUrlString)
    }
}

extension WorkspaceMetadata {

    internal static func parse(projectURLString: String) -> (CheckoutType, GitService)? {
        guard let url = NSURL(string: projectURLString) else {
            Log.error("Failed to convert urlString '\(projectURLString)' to an NSURL.")
            return nil
        }

        var checkoutType: CheckoutType?
        var gitService: GitService?

        if projectURLString.containsString(GitService.GitHub.hostname()) {
            gitService = .GitHub
        } else if projectURLString.containsString(GitService.BitBucket.hostname()) {
            gitService = .BitBucket
        } else {
            var urlPieces = projectURLString.split(":")
            gitService = GitService.createEnterpriseService(urlPieces[0])
            if gitService == nil {
                Log.error("This git service is not yet supported.")
            }
        }

        switch url.scheme {
        case "":
            // No scheme, likely to be SSH so let's check for the telltale 'git@' in the resource specifier.
            if url.resourceSpecifier.containsString("git@") {
                checkoutType = .SSH
            }
        case "ssh":
            checkoutType = .SSH
        case GitService.GitHub.hostname(), GitService.BitBucket.hostname():
            checkoutType = .SSH
        default:
            Log.error("The \(url.scheme) scheme is not yet supported.")
        }

        if let checkoutType = checkoutType, gitService = gitService {
            return (checkoutType, gitService)
        }

        Log.error("Please create an issue on GitHub if you want it added (https://github.com/czechboy0/Buildasaur/issues/new)")
        return nil
    }
    
}
