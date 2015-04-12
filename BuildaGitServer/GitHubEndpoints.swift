//
//  GitHubURLFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class GitHubEndpoints {
    
    public enum Endpoint {
        case Users, Repos, PullRequests, Branches
    }
    
    public typealias URLRequestBody = [String: AnyObject]

    private let baseURL: String
    private let token: String
    
    init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }
    
    private func endpointURL(endpoint: Endpoint, params: [String: String]? = nil) -> String {
        
        switch endpoint {
        case .Users:
            
            if let user = params?["user"] {
                return "/users/\(user)"
            } else {
                return "/user"
            }
        
        case .Repos:
            
            if let repo = params?["repo"] {
                return "/repos/\(repo)"
            } else {
                let user = self.endpointURL(.Users, params: params)
                return "\(user)/repos"
            }
            
        case .PullRequests:
            
            let repo = params!["repo"]!
            
            if let pr = params?["pr"] {
                return "/repos/\(repo)/pulls/\(pr)"
            } else {
                return "/repos/\(repo)/pulls"
            }
            
        case .Branches:
            
            let repo = self.endpointURL(.Repos, params: params)
            let branches = "\(repo)/branches"
            
            if let branch = params?["branch"] {
                return "\(branches)/\(branch)"
            } else {
                return branches
            }
            
        default:
            assertionFailure("Unsupported endpoint")
        }
    }
    
    public func createRequest(method:HTTPMethod, endpoint:Endpoint, params: [String : String]? = nil, body:URLRequestBody? = nil) -> NSMutableURLRequest? {
        
        let endpointURL = self.endpointURL(endpoint, params: params)
        let wholePath = "\(self.baseURL)\(endpointURL)"
        
        let url = NSURL(string: wholePath)!
        
        var request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method.rawValue
        request.setValue("token \(self.token)", forHTTPHeaderField:"Authorization")
        
        if let body = body {
            
            var error: NSError?
            let data = NSJSONSerialization.dataWithJSONObject(body, options: .allZeros, error: &error)
            if let error = error {
                //parsing error
                println("Parsing error \(error.description)")
                return nil
            }
            
            request.HTTPBody = data
        }
        
        return request
    }

    
}
