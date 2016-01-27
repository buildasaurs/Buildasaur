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
            case .PersonalToken, .OAuthToken:
                request.setValue("token \(auth.secret)", forHTTPHeaderField:"Authorization")
            }
        }
        
        if let body = body {
            
            let data = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions())
            request.HTTPBody = data
        }
        
        return request
    }
}