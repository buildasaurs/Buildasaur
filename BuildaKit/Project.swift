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
import ReactiveCocoa

public class Project {
    
    public var url: NSURL {
        return NSURL(fileURLWithPath: self._config.url, isDirectory: true)
    }
    
    public let config: MutableProperty<ProjectConfig>
    
    private var _config: ProjectConfig {
        return self.config.value
    }
    
    public var urlString: String { return self.url.absoluteString }
    public var privateSSHKey: String? { return self.getContentsOfKeyAtPath(self._config.privateSSHKeyPath) }
    public var publicSSHKey: String? { return self.getContentsOfKeyAtPath(self._config.publicSSHKeyPath) }
    
    public var availabilityState: AvailabilityCheckState = .Unchecked
    
    private(set) public var workspaceMetadata: WorkspaceMetadata?
    
    public init(config: ProjectConfig) throws {
        
        self.config = MutableProperty<ProjectConfig>(config)
        self.setupBindings()
        try self.refreshMetadata()
    }
    
    private init(original: Project, forkOriginURL: String) throws {
        
        self.config = MutableProperty<ProjectConfig>(original.config.value)
        self.workspaceMetadata = try original.workspaceMetadata?.duplicateWithForkURL(forkOriginURL)
    }
    
    private func setupBindings() {
        
        self.config.producer.startWithNext { [weak self] _ in
            _ = try? self?.refreshMetadata()
        }
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
    
    public func serviceRepoName() -> String? {
        
        guard let meta = self.workspaceMetadata else { return nil }
        
        let projectUrl = meta.projectURL
        let service = meta.service
        
        let originalStringUrl = projectUrl.absoluteString
        let stringUrl = originalStringUrl.lowercaseString
        
        /*
        both https and ssh repos on github have a form of:
        {https://|git@}SERVICE_URL{:|/}organization/repo.git
        here I need the organization/repo bit, which I'll do by finding "SERVICE_URL" and shifting right by one
        and scan up until ".git"
        */
        
        let serviceUrl = service.hostname().lowercaseString
        if let githubRange = stringUrl.rangeOfString(serviceUrl, options: NSStringCompareOptions(), range: nil, locale: nil),
            let dotGitRange = stringUrl.rangeOfString(".git", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) {
                
                let start = githubRange.endIndex.advancedBy(1)
                let end = dotGitRange.startIndex
                
                let repoName = originalStringUrl.substringWithRange(Range<String.Index>(start: start, end: end))
                return repoName
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

