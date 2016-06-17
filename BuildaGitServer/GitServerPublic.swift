//
//  GitSourcePublic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import Keys
import ReactiveCocoa
import Result

public enum GitService {
    case GitHub
    case EnterpriseGitHub(host: String)
    case BitBucket
//    case GitLab = "gitlab"

    public func type() -> String {
        switch self {
        case .GitHub: return "github"
        case .EnterpriseGitHub: return "enterprisegithub"
        case .BitBucket: return "bitbucket"
        }
    }

    public func prettyName() -> String {
        switch self {
        case .GitHub: return "GitHub"
        case .EnterpriseGitHub: return "EnterpriseGitHub"
        case .BitBucket: return "BitBucket"
        }
    }
    
    public func logoName() -> String {
        switch self {
        case .GitHub: return "github"
        case .EnterpriseGitHub: return "enterprisegithub"
        case .BitBucket: return "bitbucket"
        }
    }
    
    public func hostname() -> String {
        switch self {
        case .GitHub: return "github.com"
        case .EnterpriseGitHub(let host): return host
        case .BitBucket: return "bitbucket.org"
        }
    }
    
    public func authorizeUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/authorize"
        case .EnterpriseGitHub: assert(false)
        case .BitBucket: return "https://bitbucket.org/site/oauth2/authorize"
        }
    }
    
    public func accessTokenUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/access_token"
        case .EnterpriseGitHub: assert(false)
        case .BitBucket: return "https://bitbucket.org/site/oauth2/access_token"
        }
    }
    
    public func serviceKey() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientId()
        case .EnterpriseGitHub: assert(false)
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientId()
        }
    }
    
    public func serviceSecret() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientSecret()
        case .EnterpriseGitHub: assert(false)
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientSecret()
        }
    }

    public static func createEnterpriseService(host: String) -> GitService? {
        guard let url = NSURL(string: "http://\(host)") else { return nil }
        do {
            let response = try NSString.init(contentsOfURL: url, encoding: NSASCIIStringEncoding)
            if response.lowercaseString.containsString("github") {
                return GitService.EnterpriseGitHub(host: host)
            }
        } catch {
            Log.error("\(error)")
        }
        return nil
    }
}

public class GitServer : HTTPServer {
    
    let service: GitService
    
    public func authChangedSignal() -> Signal<ProjectAuthenticator?, NoError> {
        return Signal.never
    }
    
    init(service: GitService, http: HTTP? = nil) {
        self.service = service
        super.init(http: http)
    }
}

