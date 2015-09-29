//
//  SourceControlFileParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 29/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

protocol SourceControlFileParser {

    func supportedFileExtensions() -> [String]
    func parseFileAtUrl(url: NSURL) throws -> WorkspaceMetadata
}

class CheckoutFileParser: SourceControlFileParser {
    
    func supportedFileExtensions() -> [String] {
        return ["xccheckout"]
    }
    
    func parseFileAtUrl(url: NSURL) throws -> WorkspaceMetadata {
        
        //plist -> NSDictionary
        guard let dictionary = NSDictionary(contentsOfURL: url) else { throw Error.withInfo("Failed to parse \(url)") }
        
        //parse our required keys
        let projectName = dictionary.optionalStringForKey("IDESourceControlProjectName")
        let projectPath = dictionary.optionalStringForKey("IDESourceControlProjectPath")
        let projectWCCIdentifier = dictionary.optionalStringForKey("IDESourceControlProjectWCCIdentifier")
        let projectWCCName = { () -> String? in
            if let wccId = projectWCCIdentifier {
                if let wcConfigs = dictionary["IDESourceControlProjectWCConfigurations"] as? [NSDictionary] {
                    if let foundConfig = wcConfigs.filter({
                        if let loopWccId = $0.optionalStringForKey("IDESourceControlWCCIdentifierKey") {
                            return loopWccId == wccId
                        }
                        return false
                    }).first {
                        //so much effort for this little key...
                        return foundConfig.optionalStringForKey("IDESourceControlWCCName")
                    }
                }
            }
            return nil
            }()
        let projectURLString = { dictionary.optionalStringForKey("IDESourceControlProjectURL") }()
        
        return try WorkspaceMetadata(projectName: projectName, projectPath: projectPath, projectWCCIdentifier: projectWCCIdentifier, projectWCCName: projectWCCName, projectURLString: projectURLString)
    }
}

class BlueprintFileParser: SourceControlFileParser {
    
    func supportedFileExtensions() -> [String] {
        return ["xcscmblueprint"]
    }
    
    func parseFileAtUrl(url: NSURL) throws -> WorkspaceMetadata {
        throw Error.withInfo("Not yet supported")
    }
}

