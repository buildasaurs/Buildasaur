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
    case BitBucket = "bitbucket"
    case GitLab = "gitlab"
    
    public func prettyName() -> String {
        switch self {
        case .GitHub: return "GitHub"
        case .BitBucket: return "BitBucket"
        case .GitLab: return "GitLab"
        }
    }
    
    public func logoName() -> String {
        switch self {
        case .GitHub: return "github"
        case .BitBucket: return "bitbucket"
        case .GitLab: return "gitlab"
        }
    }
    
    public func hostname() -> String {
        switch self {
        case .GitHub: return "github.com"
        case .BitBucket: return "bitbucket.org"
        case .GitLab: return "gitlab.com"
        }
    }
    
    public func authorizeUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/authorize"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/authorize"
        case .GitLab: return "https://gitlab.com/oauth/authorize"
        }
    }
    
    public func accessTokenUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/access_token"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/access_token"
        case .GitLab: return "https://gitlab.com/oauth/token"
        }
    }
    
    public func serviceKey() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientId()
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientId()
        case .GitLab: return BuildasaurKeys().gitLabAPIClientId()
        }
    }
    
    public func serviceSecret() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientSecret()
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientSecret()
        case .GitLab: return BuildasaurKeys().gitLabAPIClientSecret()
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

