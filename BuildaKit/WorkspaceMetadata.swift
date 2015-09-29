//
//  WorkspaceMetadata.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 29/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

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
    public let checkoutType: CheckoutType
    
    init(projectName: String?, projectPath: String?, projectWCCIdentifier: String?, projectWCCName: String?, projectURL: NSURL?) throws {
        
        let errorForMissingKey: (String) -> ErrorType = { Error.withInfo("Can't find/parse \"\($0)\" in workspace metadata!") }
        guard let projectName = projectName else { throw errorForMissingKey("Project Name") }
        guard let projectPath = projectPath else { throw errorForMissingKey("Project Path") }
        guard let projectWCCIdentifier = projectWCCIdentifier else { throw errorForMissingKey("Project WCC Identifier") }
        guard let projectWCCName = projectWCCName else { throw errorForMissingKey("Project WCC Name") }
        guard let projectURL = projectURL else { throw errorForMissingKey("Project URL") }
        guard let checkoutType = WorkspaceMetadata.parseCheckoutType(projectURL) else {
            let allowedString = [CheckoutType.SSH].map({ $0.rawValue }).joinWithSeparator(", ")
            let error = Error.withInfo("Disallowed checkout type, the project must be checked out over one of the supported schemes: \(allowedString)")
            throw error
        }
        
        self.projectName = projectName
        self.projectPath = projectPath
        self.projectWCCIdentifier = projectWCCIdentifier
        self.projectWCCName = projectWCCName
        self.projectURL = projectURL
        self.checkoutType = checkoutType
    }
    
    func duplicateWithForkURL(forkUrlString: String?) throws -> WorkspaceMetadata {
        let forkUrl = NSURL(string: forkUrlString ?? "")
        return try WorkspaceMetadata(projectName: self.projectName, projectPath: self.projectPath, projectWCCIdentifier: self.projectWCCIdentifier, projectWCCName: self.projectWCCName, projectURL: forkUrl)
    }
}

extension WorkspaceMetadata {
    
    internal static func parseCheckoutType(projectURL: NSURL) -> CheckoutType? {
        
        let urlString = projectURL.absoluteString
        let scheme = projectURL.scheme
        switch scheme {
        case "github.com":
            return CheckoutType.SSH
        case "https":
            
            if urlString.hasSuffix(".git") {
                //HTTPS git
            } else {
                //SVN
            }
            
            Log.error("HTTPS or SVN not yet supported, please create an issue on GitHub if you want it added (czechboy0/Buildasaur)")
            return nil
        default:
            return nil
        }
    }
}
