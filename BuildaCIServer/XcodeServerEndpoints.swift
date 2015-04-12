//
//  XcodeServerEndpoints.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class XcodeServerEndPoints {
    
    enum Endpoint {
        case Bots
        case Integrations
        case CancelIntegration
        case UserCanCreateBots
        case Devices
        case Login
        case Logout
    }
    
    let serverConfig: XcodeServerConfig
    
    public init(serverConfig: XcodeServerConfig) {
        
        self.serverConfig = serverConfig
    }
    
    private func endpointURL(endpoint: Endpoint, params: [String: String]? = nil) -> String {
        
        let base = "/xcode/api"
        
        switch endpoint {
            
        case .Bots:
            
            let bots = "\(base)/bots"
            if let bot = params?["bot"] {
                let bot = "\(bots)/\(bot)"
                if let rev = params?["rev"] {
                    let rev = "\(bot)/\(rev)"
                    return rev
                }
                return bot
            }
            return bots
            
        case .Integrations:
            
            if let bot = params?["bot"] {
                //gets a list of integrations for this bot
                let bots = self.endpointURL(.Bots, params: params)
                return "\(bots)/integrations"
            }
            
            let integrations = "\(base)/integrations"
            if let integration = params?["integration"] {
                
                let oneIntegration = "\(integrations)/\(integration)"
                return oneIntegration
            }
            return integrations
            
        case .CancelIntegration:
            
            let integration = self.endpointURL(.Integrations, params: params)
            let cancel = "\(integration)/cancel"
            return cancel
            
        case .Devices:
            
            let devices = "\(base)/devices"
            return devices
            
        case .UserCanCreateBots:
            
            let users = "\(base)/auth/isBotCreator"
            return users
            
        case .Login:
            
            let login = "\(base)/auth/login"
            return login
            
        case .Logout:
            
            let logout = "\(base)/auth/logout"
            return logout
            
        default:
            assertionFailure("Unsupported endpoint")
        }
    }
    
    func createRequest(method: HTTP.Method, endpoint: Endpoint, params: [String : String]? = nil, query: [String : String]? = nil, body:NSDictionary? = nil, doBasicAuth: Bool = true) -> NSMutableURLRequest? {
        
        let endpointURL = self.endpointURL(endpoint, params: params)
        let queryString = HTTP.stringForQuery(query)
        let wholePath = "\(self.serverConfig.host)\(endpointURL)\(queryString)"
        
        if let url = NSURL(string: wholePath) {
            
            var request = NSMutableURLRequest(URL: url)
            
            request.HTTPMethod = method.rawValue
            
            if doBasicAuth {
                //add authorization header
                let user = self.serverConfig.user ?? ""
                let password = self.serverConfig.password ?? ""
                let plainString = "\(user):\(password)" as NSString
                let plainData = plainString.dataUsingEncoding(NSUTF8StringEncoding)
                let base64String = plainData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
                request.setValue("Basic \(base64String!)", forHTTPHeaderField: "Authorization")
            }
            
            if let body = body {
                
                var error: NSError?
                let data = NSJSONSerialization.dataWithJSONObject(body, options: .allZeros, error: &error)
                if let error = error {
                    //parsing error
                    println("Parsing error \(error.description)")
                    return nil
                }
                
                request.HTTPBody = data
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            return request
        }
        return nil
    }
    
}
