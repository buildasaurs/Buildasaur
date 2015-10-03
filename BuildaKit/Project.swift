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

public class Project : JSONSerializable {
    
    public var url: NSURL {
        return NSURL(string: self.config.url)!
    }
    
    public var config: ProjectConfig {
        didSet {
            _ = try? self.refreshMetadata()
        }
    }
    
    public var urlString: String { return self.url.absoluteString }
    public var privateSSHKey: String? { return self.getContentsOfKeyAtPath(self.config.privateSSHKeyPath) }
    public var publicSSHKey: String? { return self.getContentsOfKeyAtPath(self.config.publicSSHKeyPath) }
    
    public var availabilityState: AvailabilityCheckState
    
    private(set) public var workspaceMetadata: WorkspaceMetadata?
    
    public init?(url: NSURL) {
        
        self.url = url
        self.preferredTemplateId = nil
        self.githubToken = nil
        self.availabilityState = .Unchecked
        self.publicSSHKeyUrl = nil
        self.privateSSHKeyUrl = nil
        self.sshPassphrase = nil
        do {
            try self.refreshMetadata()
        } catch {
            Log.error(error)
            return nil
        }
    }
    
    private init(original: Project, forkOriginURL: String) throws {
        
        self.url = original.url
        self.preferredTemplateId = original.preferredTemplateId
        self.githubToken = original.githubToken
        self.availabilityState = original.availabilityState
        self.publicSSHKeyUrl = original.publicSSHKeyUrl
        self.privateSSHKeyUrl = original.privateSSHKeyUrl
        self.sshPassphrase = original.sshPassphrase
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
    
    public required init(json: NSDictionary) throws {
        
        self.availabilityState = .Unchecked
        
        if
            let urlString = json.optionalStringForKey("url"),
            let url = NSURL(string: urlString)
        {
            
            self.url = url
            self.preferredTemplateId = json.optionalStringForKey("preferred_template_id")
            self.githubToken = json.optionalStringForKey("github_token")
            if let publicKeyUrl = json.optionalStringForKey("ssh_public_key_url") {
                self.publicSSHKeyUrl = NSURL(string: publicKeyUrl)
            } else {
                self.publicSSHKeyUrl = nil
            }
            if let privateKeyUrl = json.optionalStringForKey("ssh_private_key_url") {
                self.privateSSHKeyUrl = NSURL(string: privateKeyUrl)
            } else {
                self.privateSSHKeyUrl = nil
            }
            self.sshPassphrase = json.optionalStringForKey("ssh_passphrase")
            
            do {
                try self.refreshMetadata()
            } catch {
                Log.error("Error parsing: \(error)")
                throw error
            }
            
        } else {
            
            self.url = NSURL()
            self.preferredTemplateId = nil
            self.githubToken = nil
            self.publicSSHKeyUrl = nil
            self.privateSSHKeyUrl = nil
            self.sshPassphrase = nil
            self.workspaceMetadata = nil
            throw Error.withInfo("No Url")
        }
    }
    
    public init() {
        self.availabilityState = .Unchecked
        self.url = NSURL()
        self.preferredTemplateId = nil
        self.githubToken = nil
        self.publicSSHKeyUrl = nil
        self.privateSSHKeyUrl = nil
        self.sshPassphrase = nil
        self.workspaceMetadata = nil
    }
    
    public func jsonify() -> NSDictionary {
        
        let json = NSMutableDictionary()
        
        json["url"] = self.url.absoluteString
        json.optionallyAddValueForKey(self.preferredTemplateId, key: "preferred_template_id")
        json.optionallyAddValueForKey(self.githubToken, key: "github_token")
        json.optionallyAddValueForKey(self.publicSSHKeyUrl?.absoluteString, key: "ssh_public_key_url")
        json.optionallyAddValueForKey(self.privateSSHKeyUrl?.absoluteString, key: "ssh_private_key_url")
        json.optionallyAddValueForKey(self.sshPassphrase, key: "ssh_passphrase")
        
        return json
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
        
        let url = NSURL(string: path)!
        do {
            let key = try NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding)
            return key as String
        } catch {
            Log.error("Couldn't load key at url \(url) with error \(error)")
        }
        return nil
    }

}

