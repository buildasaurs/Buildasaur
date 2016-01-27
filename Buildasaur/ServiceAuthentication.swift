//
//  ServiceAuthentication.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/26/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import OAuthSwift
import BuildaGitServer
import Keys

class ServiceAuthenticator {
    
    enum ParamKey: String {
        case ConsumerId
        case ConsumerSecret
        case AuthorizeUrl
        case AccessTokenUrl
        case ResponseType
        case CallbackUrl
        case Scope
        case State
    }
    
    init() {}
    
    func handleUrl(url: NSURL) {
        OAuthSwift.handleOpenURL(url)
    }
    
    func getAccess(service: GitService, completion: (auth: ProjectAuthenticator?, error: ErrorType?) -> ()) {
        
        let params = self.paramsForService(service)
        
        let oauth = OAuth2Swift(
            consumerKey: params[.ConsumerId]!,
            consumerSecret: params[.ConsumerSecret]!,
            authorizeUrl: params[.AuthorizeUrl]!,
            accessTokenUrl: params[.AccessTokenUrl]!,
            responseType: params[.ResponseType]!
        )
        oauth.authorizeWithCallbackURL(
            NSURL(string: params[.CallbackUrl]!)!,
            scope: params[.Scope]!,
            state: params[.State]!,
            success: { credential, response, parameters in
                
                let auth = ProjectAuthenticator(service: service, username: "GIT", type: .OAuthToken, secret: credential.oauth_token)
                completion(auth: auth, error: nil)
            },
            failure: { error in
                completion(auth: nil, error: error)
            }
        )
    }
    
    private func paramsForService(service: GitService) -> [ParamKey: String] {
        switch service {
        case .GitHub:
            return self.getGitHubParameters()
        default:
            fatalError()
        }
    }
    
    private func getGitHubParameters() -> [ParamKey: String] {
        let keys = BuildasaurKeys()
        return [
            .ConsumerId: keys.gitHubAPIClientId(),
            .ConsumerSecret: keys.gitHubAPIClientSecret(),
            .AuthorizeUrl: "https://github.com/login/oauth/authorize",
            .AccessTokenUrl: "https://github.com/login/oauth/access_token",
            .ResponseType: "code",
            .CallbackUrl: "buildasaur://oauth-callback/github",
            .Scope: "repo",
            .State: generateStateWithLength(20) as String
        ]
    }
}
