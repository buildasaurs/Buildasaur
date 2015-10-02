//
//  XcodeProjectXMLParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 02/10/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import Ji

class XcodeProjectXMLParser {
    
    enum WorkspaceParsingError: ErrorType {
        case ParsingFailed
        case FailedToFindWorkspaceNode
        case NoProjectsFound
        case NoLocationInProjectFound
    }
    
    static func parseProjectsInsideOfWorkspace(url: NSURL) throws -> [NSURL] {
        
        let contentsUrl = url.URLByAppendingPathComponent("contents.xcworkspacedata")
        
        guard let jiDoc = Ji(contentsOfURL: contentsUrl, isXML: true) else { throw WorkspaceParsingError.ParsingFailed }
        guard
            let workspaceNode = jiDoc.rootNode,
            let workspaceTag = workspaceNode.tag where workspaceTag == "Workspace" else { throw WorkspaceParsingError.FailedToFindWorkspaceNode }
        
        let projects = workspaceNode.childrenWithName("FileRef")
        guard projects.count > 0 else { throw WorkspaceParsingError.NoProjectsFound }
        
        let locations = try projects.map { projectNode throws -> String in
            guard let location = projectNode["location"] else { throw WorkspaceParsingError.NoLocationInProjectFound }
            return location
        }
        
        let parsedRelativePaths = locations.map { $0.componentsSeparatedByString(":").last! }
        let absolutePaths = parsedRelativePaths.map { return url.URLByAppendingPathComponent("..").URLByAppendingPathComponent($0) }
        return absolutePaths
    }
}
