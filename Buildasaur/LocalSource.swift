//
//  LocalSource.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class LocalSource : JSONSerializable {
    
    enum AllowedCheckoutTypes: String {
        case SSH = "SSH"
//        case HTTPS - not yet supported, right now only SSH is supported
//        (for bots reasons, will be built in when I have time)
//        case SVN - not yet supported yet
    }
    
    var url: NSURL {
        didSet {
            self.refreshMetadata()
        }
    }
    
    var preferredTemplateId: String?
    var githubToken: String?
    var privateSSHKeyUrl: NSURL?
    var publicSSHKeyUrl: NSURL?
    var privateSSHKey: String? { return self.getContentsOfKeyAtUrl(self.privateSSHKeyUrl) }
    var publicSSHKey: String? { return self.getContentsOfKeyAtUrl(self.publicSSHKeyUrl) }
    
    var availabilityState: AvailabilityCheckState
    
    private(set) var workspaceMetadata: NSDictionary?
    let forkOriginURL: String?
    
    //convenience getters
    var projectName: String? { get { return self.pullValueForKey("IDESourceControlProjectName") }}
    var projectPath: String? { get { return self.pullValueForKey("IDESourceControlProjectPath") }}
    var projectWCCIdentifier: String? { get { return self.pullValueForKey("IDESourceControlProjectWCCIdentifier") }}
    var projectWCCName: String? {
        get {
            if let wccId = self.projectWCCIdentifier {
                if let wcConfigs = self.workspaceMetadata?["IDESourceControlProjectWCConfigurations"] as? [NSDictionary] {
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
        }
    }
    var projectURL: NSURL? {
        get {
            if let urlString = self.pullValueForKey("IDESourceControlProjectURL") {
                
                //if we have a fork, chose its URL, otherwise fallback to the loaded URL from the Checkout file
                var finalUrlString = self.forkOriginURL ?? urlString
                let type = self.checkoutType!
                if type == .SSH {
                    if !finalUrlString.hasPrefix("git@") {
                        finalUrlString = "git@\(finalUrlString)"
                    }
                }

                return NSURL(string: finalUrlString)
            }
            return nil
        }
    }
    
    var checkoutType: AllowedCheckoutTypes? {
        get {
            if
                let meta = self.workspaceMetadata,
                let type = LocalSource.parseCheckoutType(meta) {
                    return type
            }
            return nil
        }
    }

    private func pullValueForKey(key: String) -> String? {
        return self.workspaceMetadata?.optionalStringForKey(key)
    }
    
    init?(url: NSURL) {
        
        self.forkOriginURL = nil
        self.url = url
        self.preferredTemplateId = nil
        self.githubToken = nil
        self.availabilityState = .Unchecked
        self.publicSSHKeyUrl = nil
        self.privateSSHKeyUrl = nil
        let (parsed, error) = self.refreshMetadata()
        if !parsed {
            return nil
        }
    }
    
    private init?(original: LocalSource, forkOriginURL: String) {
        
        self.forkOriginURL = forkOriginURL
        self.url = original.url
        self.preferredTemplateId = original.preferredTemplateId
        self.githubToken = original.githubToken
        self.availabilityState = original.availabilityState
        self.publicSSHKeyUrl = original.publicSSHKeyUrl
        self.privateSSHKeyUrl = original.privateSSHKeyUrl
        let (parsed, error) = self.refreshMetadata()
        if !parsed {
            return nil
        }
    }
    
    public func duplicateForForkAtOriginURL(forkURL: String) -> LocalSource? {
        
        return LocalSource(original: self, forkOriginURL: forkURL)
    }
    
    public class func attemptToParseFromUrl(url: NSURL) -> (Bool, NSDictionary?, NSError?) {
        
        let (meta, error) = LocalSource.loadWorkspaceMetadata(url)
        if let error = error {
            return (false, nil, error)
        }
        
        //validate allowed remote url
        if self.parseCheckoutType(meta!) == nil {
            //disallowed
            let allowedString = ", ".join([AllowedCheckoutTypes.SSH].map({ $0.rawValue }))
            let error = Errors.errorWithInfo("Disallowed checkout type, the project must be checked out over one of the supported schemes: \(allowedString)")
            return (false, nil, error)
        }
        
        return (true, meta, nil)
    }
    
    private class func parseCheckoutType(metadata: NSDictionary) -> AllowedCheckoutTypes? {
        
        if
            let urlString = metadata.optionalStringForKey("IDESourceControlProjectURL"),
            let url = NSURL(string: urlString),
            let scheme = url.scheme
        {
            switch scheme {
            case "github.com":
                return AllowedCheckoutTypes.SSH
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
        } else {
            return nil
        }
    }

    private func refreshMetadata() -> (Bool, NSError?) {
        
        let (allowed, meta, error) = LocalSource.attemptToParseFromUrl(self.url)
        if !allowed {
            return (false, error)
        }
        
        if let meta = meta {
            
            self.workspaceMetadata = meta
            return (true, nil)
        } else {
            return (false, error)
        }
    }
    
    public required init?(json: NSDictionary) {
        
        self.forkOriginURL = nil
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
            let (success, error) = self.refreshMetadata()
            if !success {
                Log.error("Error parsing: \(error)")
                return nil
            }
            
        } else {
            
            self.url = NSURL()
            self.preferredTemplateId = nil
            self.githubToken = nil
            self.publicSSHKeyUrl = nil
            self.privateSSHKeyUrl = nil
            return nil
        }
    }
    
    public func jsonify() -> NSDictionary {
        
        var json = NSMutableDictionary()
        
        json["url"] = self.url.absoluteString!
        json.optionallyAddValueForKey(self.preferredTemplateId, key: "preferred_template_id")
        json.optionallyAddValueForKey(self.githubToken, key: "github_token")
        json.optionallyAddValueForKey(self.publicSSHKeyUrl?.absoluteString, key: "ssh_public_key_url")
        json.optionallyAddValueForKey(self.privateSSHKeyUrl?.absoluteString, key: "ssh_private_key_url")
        
        return json
    }
    
    public func schemeNames() -> [String] {
        
        let schemes = XcodeProjectParser.sharedSchemeUrlsFromProjectOrWorkspaceUrl(self.url)
        let names = schemes.map { $0.lastPathComponent!.stringByDeletingPathExtension }
        return names
    }
    
    private class func loadWorkspaceMetadata(url: NSURL) -> (NSDictionary?, NSError?) {
        
        return XcodeProjectParser.parseRepoMetadataFromProjectOrWorkspaceURL(url)
    }
    
    public func githubRepoName() -> String? {
        
        if let projectUrl = self.projectURL {
            let originalStringUrl = projectUrl.absoluteString!
            let stringUrl = originalStringUrl.lowercaseString
            
            /*
            both https and ssh repos on github have a form of:
            {https://|git@}github.com{:|/}organization/repo.git
            here I need the organization/repo bit, which I'll do by finding "github.com" and shifting right by one
            and scan up until ".git"
            */
            
            if let githubRange = stringUrl.rangeOfString("github.com", options: NSStringCompareOptions.allZeros, range: nil, locale: nil),
                let dotGitRange = stringUrl.rangeOfString(".git", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) {
                    
                    let start = advance(githubRange.endIndex, 1)
                    let end = dotGitRange.startIndex
                    
                    let repoName = originalStringUrl.substringWithRange(Range<String.Index>(start: start, end: end))
                    return repoName
            }
        }
        return nil
    }
    
    private func getContentsOfKeyAtUrl(url: NSURL?) -> String? {
        
        if let url = url {
            var error: NSError?
            if let key = NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding, error: &error) {
                return key as String
            }
            Log.error("Couldn't load key at url \(url) with error \(error)")
            return nil
        }
        Log.error("Couldn't load key at nil url")
        return nil
    }
    
    

    
}

