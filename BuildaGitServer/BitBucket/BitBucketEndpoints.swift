//
//  BitBucketEndpoints.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

class BitBucketEndpoints {
    
    enum Endpoint {
        case Repos
        case PullRequests
        case PullRequestComments
        case CommitStatuses
    }
    
    private let baseURL: String
    private let auth: ProjectAuthenticator?
    
    init(baseURL: String, auth: ProjectAuthenticator?) {
        self.baseURL = baseURL
        self.auth = auth
    }
    
    private func endpointURL(endpoint: Endpoint, params: [String: String]? = nil) -> String {
        
        switch endpoint {
            
        case .Repos:
            
            if let repo = params?["repo"] {
                return "/2.0/repositories/\(repo)"
            } else {
                return "/2.0/repositories"
            }
            
        case .PullRequests:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            let repo = self.endpointURL(.Repos, params: params)
            
            if let pr = params?["pr"] {
                return "\(repo)/pullrequests/\(pr)"
            } else {
                return "\(repo)/pullrequests"
            }
        
        case .PullRequestComments:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            assert(params?["pr"] != nil, "A PR must be specified")
            let pr = self.endpointURL(.PullRequests, params: params)
            return "\(pr)/comments"
            
        case .CommitStatuses:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            assert(params?["sha"] != nil, "A commit sha must be specified")
            let repo = self.endpointURL(.Repos, params: params)
            let sha = params!["sha"]!
            
            let build = "\(repo)/commit/\(sha)/statuses/build"
            
            if let key = params?["status_key"] {
                return "\(build)/\(key)"
            }
            
            return build
            
        }
        
    }
    
    func createRequest(method: HTTP.Method, endpoint: Endpoint, params: [String : String]? = nil, query: [String : String]? = nil, body: NSDictionary? = nil) throws -> NSMutableURLRequest {
        
        let endpointURL = self.endpointURL(endpoint, params: params)
        let queryString = HTTP.stringForQuery(query)
        let wholePath = "\(self.baseURL)\(endpointURL)\(queryString)"
        
        let url = NSURL(string: wholePath)!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method.rawValue
        if let auth = self.auth {
            
            switch auth.type {
            case .OAuthToken:
                let tokens = auth.secret.componentsSeparatedByString(":")
                //first is refresh token, second access token
                request.setValue("Bearer \(tokens[1])", forHTTPHeaderField:"Authorization")
            default:
                fatalError("This kind of authentication is not supported for BitBucket")
            }
        }
        
        if let body = body {
            
            let data = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions())
            request.HTTPBody = data
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}