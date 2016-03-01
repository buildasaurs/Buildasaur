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

public enum GitService: String {
    case GitHub = "github"
    case EnterpriseGitHub = "enterprisegithub"
    case BitBucket = "bitbucket"
//    case GitLab = "gitlab"
    
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
        case .EnterpriseGitHub: return BuildasaurxcodeprojKeys().enterpriseGitHubHostname()
        case .BitBucket: return "bitbucket.org"
        }
    }
    
    public func authorizeUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/authorize"
        case .EnterpriseGitHub: return "https://\(hostname())/login/oauth/authorize"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/authorize"
        }
    }
    
    public func accessTokenUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/access_token"
        case .EnterpriseGitHub: return "https://\(hostname())/login/oauth/access_token"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/access_token"
        }
    }
    
    public func serviceKey() -> String {
        switch self {
        case .GitHub: return BuildasaurxcodeprojKeys().gitHubAPIClientId()
        case .EnterpriseGitHub: return BuildasaurxcodeprojKeys().enterpriseGitHubAPIClientId()
        case .BitBucket: return BuildasaurxcodeprojKeys().bitBucketAPIClientId()
        }
    }
    
    public func serviceSecret() -> String {
        switch self {
        case .GitHub: return BuildasaurxcodeprojKeys().gitHubAPIClientSecret()
        case .EnterpriseGitHub: return BuildasaurxcodeprojKeys().enterpriseGitHubAPIClientSecret()
        case .BitBucket: return BuildasaurxcodeprojKeys().bitBucketAPIClientSecret()
        }
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

