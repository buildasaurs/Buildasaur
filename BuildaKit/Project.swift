//
//  Project.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK

public class Project {
    
    public var url: NSURL {
        return NSURL(fileURLWithPath: self.config.url)
    }
    
    public var config: ProjectConfig {
        didSet {
            _ = try? self.refreshMetadata()
        }
    }
    
    public var urlString: String { return self.url.absoluteString }
    public var privateSSHKey: String? { return self.getContentsOfKeyAtPath(self.config.privateSSHKeyPath) }
    public var publicSSHKey: String? { return self.getContentsOfKeyAtPath(self.config.publicSSHKeyPath) }
    
    public var availabilityState: AvailabilityCheckState = .Unchecked
    
    private(set) public var workspaceMetadata: WorkspaceMetadata?
    
    public init(config: ProjectConfig) throws {
        
        self.config = config
        try self.refreshMetadata()
    }
    
    private init(original: Project, forkOriginURL: String) throws {
        
        self.config = original.config
        self.availabilityState = .Unchecked
        self.workspaceMetadata = try original.workspaceMetadata?.duplicateWithForkURL(forkOriginURL)
    }
    
    public func duplicateForForkAtOriginURL(forkURL: String) throws -> Project {
        return try Project(original: self, forkOriginURL: forkURL)
    }
    
    public class func attemptToParseFromUrl(url: NSURL) throws -> WorkspaceMetadata {
        return try Project.loadWorkspaceMetadata(url)
    }

    private func refreshMetadata() throws {
        let meta = try Project.attemptToParseFromUrl(self.url)
        self.workspaceMetadata = meta
    }
    
    public func schemes() -> [XcodeScheme] {
        
        let schemes = XcodeProjectParser.sharedSchemesFromProjectOrWorkspaceUrl(self.url)
        return schemes
    }
    
    private class func loadWorkspaceMetadata(url: NSURL) throws -> WorkspaceMetadata {
        
        return try XcodeProjectParser.parseRepoMetadataFromProjectOrWorkspaceURL(url)
    }
    
    public func githubRepoName() -> String? {
        
        if let projectUrl = self.workspaceMetadata?.projectURL {
            let originalStringUrl = projectUrl.absoluteString
            let stringUrl = originalStringUrl.lowercaseString
            
            /*
            both https and ssh repos on github have a form of:
            {https://|git@}github.com{:|/}organization/repo.git
            here I need the organization/repo bit, which I'll do by finding "github.com" and shifting right by one
            and scan up until ".git"
            */
            
            if let githubRange = stringUrl.rangeOfString("github.com", options: NSStringCompareOptions(), range: nil, locale: nil),
                let dotGitRange = stringUrl.rangeOfString(".git", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) {
                    
                    let start = githubRange.endIndex.advancedBy(1)
                    let end = dotGitRange.startIndex
                    
                    let repoName = originalStringUrl.substringWithRange(Range<String.Index>(start: start, end: end))
                    return repoName
            }
        }
        return nil
    }
    
    private func getContentsOfKeyAtPath(path: String) -> String? {
        
        let url = NSURL(fileURLWithPath: path)
        do {
            let key = try NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding)
            return key as String
        } catch {
            Log.error("Couldn't load key at url \(url) with error \(error)")
        }
        return nil
    }

}

