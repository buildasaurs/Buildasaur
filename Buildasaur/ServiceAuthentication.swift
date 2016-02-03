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
    
    typealias SecretFromResponseParams = ([String: String]) -> String
    
    init() {}
    
    func handleUrl(url: NSURL) {
        OAuthSwift.handleOpenURL(url)
    }
    
    func getAccess(service: GitService, completion: (auth: ProjectAuthenticator?, error: ErrorType?) -> ()) {
        
        let (params, secretFromResponseParams) = self.paramsForService(service)
        
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
                
                let secret = secretFromResponseParams(parameters)
                let auth = ProjectAuthenticator(service: service, username: "GIT", type: .OAuthToken, secret: secret)
                completion(auth: auth, error: nil)
            },
            failure: { error in
                completion(auth: nil, error: error)
            }
        )
    }
    
    func getAccessTokenFromRefresh(service: GitService, refreshToken: String, completion: (auth: ProjectAuthenticator?, error: ErrorType?)) {
        //TODO: implement refresh token flow - to get and save a new access token
    }
    
    private func paramsForService(service: GitService) -> ([ParamKey: String], SecretFromResponseParams) {
        switch service {
        case .GitHub:
            return self.getGitHubParameters()
        case .BitBucket:
            return self.getBitBucketParameters()
//        default:
//            fatalError()
        }
    }
    
    private func getGitHubParameters() -> ([ParamKey: String], SecretFromResponseParams) {
        let service = GitService.GitHub
        let params: [ParamKey: String] = [
            .ConsumerId: service.serviceKey(),
            .ConsumerSecret: service.serviceSecret(),
            .AuthorizeUrl: service.authorizeUrl(),
            .AccessTokenUrl: service.accessTokenUrl(),
            .ResponseType: "code",
            .CallbackUrl: "buildasaur://oauth-callback/github",
            .Scope: "repo",
            .State: generateStateWithLength(20) as String
        ]
        let secret: SecretFromResponseParams = {
            //just pull out the access token, that's all we need
            return $0["access_token"]!
        }
        return (params, secret)
    }
    
    private func getBitBucketParameters() -> ([ParamKey: String], SecretFromResponseParams) {
        let service = GitService.BitBucket
        let params: [ParamKey: String] = [
            .ConsumerId: service.serviceKey(),
            .ConsumerSecret: service.serviceSecret(),
            .AuthorizeUrl: service.authorizeUrl(),
            .AccessTokenUrl: service.accessTokenUrl(),
            .ResponseType: "code",
            .CallbackUrl: "buildasaur://oauth-callback/bitbucket",
            .Scope: "pullrequest",
            .State: generateStateWithLength(20) as String
        ]
        let secret: SecretFromResponseParams = {
            //we need both the access and refresh tokens, because
            //the refresh token only lives for one hour.
            //but we'll only store the
            let refreshToken = $0["refresh_token"]!
            let accessToken = $0["access_token"]!
            return "\(refreshToken):\(accessToken)"
        }
        return (params, secret)
    }

}
