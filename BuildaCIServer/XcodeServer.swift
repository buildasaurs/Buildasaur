//
//  XcodeServer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class XcodeServerConfig : JSONSerializable {
    
    public let host: String
    public let user: String?
    public let password: String?

    public var availabilityState: AvailabilityCheckState

    public func jsonify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        dict["host"] = self.host
        dict.optionallyAddValueForKey(self.user, key: "user")
        dict.optionallyAddValueForKey(self.password, key: "password")
        return dict
    }
    
    public init(var host: String, user: String? = nil, password: String? = nil) {
        
        //validate host by running through URL and seeing the scheme
        if let url = NSURL(string: host) {
            if let scheme = url.scheme {
                if scheme != "https" {
                    //show a popup that it should be https!
                    UIUtils.showAlertWithText("Xcode Server generally uses https, please double check your hostname")
                }
            } else {
                //no scheme, add https://
                host = "https://" + host
            }
        }
        
        self.host = host
        self.user = user
        self.password = password
        self.availabilityState = .Unchecked
    }
    
    public required init?(json: NSDictionary) {
        
        self.availabilityState = .Unchecked

        if let host = json.optionalStringForKey("host") {
                
                self.host = host
                self.user = json.optionalStringForKey("user")
                self.password = json.optionalStringForKey("password")
                
        } else {
            self.host = ""
            self.user = nil
            self.password = nil
            return nil
        }
    }
}

public class XcodeServer : CIServer {
    
    public let config: XcodeServerConfig
    let endpoints: XcodeServerEndPoints
    
    public init(config: XcodeServerConfig, endpoints: XcodeServerEndPoints) {
        
        self.config = config
        self.endpoints = endpoints
        
        super.init()
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let delegate: NSURLSessionDelegate = self
        let queue = NSOperationQueue.mainQueue()
        let session = NSURLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
        self.http.session = session
    }
    
}

extension XcodeServer : NSURLSessionDelegate {
    
    var credential: NSURLCredential? {
        
        if
            let user = self.config.user,
            let password = self.config.password {
                return NSURLCredential(user: user, password: password, persistence: NSURLCredentialPersistence.None)
        }
        return nil
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        
        var disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
        var credential: NSURLCredential?
        
        if challenge.previousFailureCount > 0 {
            disposition = .CancelAuthenticationChallenge
        } else {
            
            switch challenge.protectionSpace.authenticationMethod! {
                
            case NSURLAuthenticationMethodServerTrust:
                credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust)
            default:
                credential = self.credential ?? session.configuration.URLCredentialStorage?.defaultCredentialForProtectionSpace(challenge.protectionSpace)
            }
            
            if credential != nil {
                disposition = .UseCredential
            }
        }

        completionHandler(disposition, credential)
    }
}

public extension XcodeServer {
    
    //API functionality
    
    private func sendRequestWithMethod(method: HTTP.Method, endpoint: XcodeServerEndPoints.Endpoint, params: [String: String]?, query: [String: String]?, body: NSDictionary?, completion: HTTP.Completion) {
        
        var allParams = [
            "method": method.rawValue
        ]
        
        //merge the two params
        if let params = params {
            for (let key, let value) in params {
                allParams[key] = value
            }
        }
        
        if let request = self.endpoints.createRequest(method, endpoint: endpoint, params: allParams, query: query, body: body) {
            
            self.http.sendRequest(request, completion: { (response, body, error) -> () in
                
                if response == nil {
                    completion(response: nil, body: body, error: Errors.errorWithInfo("Nil response"))
                    return
                }
                
                completion(response: response, body: body, error: error)
            })
            
        } else {
            completion(response: nil, body: nil, error: Errors.errorWithInfo("Couldn't create Request"))
        }
    }
    
    public func login(completion: (success: Bool, error: NSError?) -> ()) {
        
        self.sendRequestWithMethod(.POST, endpoint: .Login, params: nil, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(success: false, error: error)
                return
            }
            
            if let response = response {
                if response.statusCode == 204 {
                    completion(success: true, error: nil)
                } else {
                    completion(success: false, error: Errors.errorWithInfo("Wrong status code: \(response.statusCode)"))
                }
                return
            }
            completion(success: false, error: Errors.errorWithInfo("Nil response"))
        }
    }
    
    public func logout(completion: (success: Bool, error: NSError?) -> ()) {
        
        self.sendRequestWithMethod(.POST, endpoint: .Logout, params: nil, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(success: false, error: error)
                return
            }
            
            if let response = response {
                if response.statusCode == 204 {
                    completion(success: true, error: nil)
                } else {
                    completion(success: false, error: Errors.errorWithInfo("Wrong status code: \(response.statusCode)"))
                }
                return
            }
            completion(success: false, error: Errors.errorWithInfo("Nil response"))
        }
    }

    public func createBot(botOrder: Bot, completion: (bot: Bot?, error: NSError?) -> ()) {
        
        let body: NSDictionary = botOrder.dictionarify()
        
        self.sendRequestWithMethod(.POST, endpoint: .Bots, params: nil, query: nil, body: body) { (response, body, error) -> () in

            if error != nil {
                completion(bot: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let bot = Bot(json: body as NSDictionary)
                completion(bot: bot, error: nil)
            } else {
                completion(bot: nil, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
    public func getBot(botTinyId: String, completion: (bot: Bot?, error: NSError?) -> ()) {
        
        let params = [
            "bot": botTinyId
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Bots, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(bot: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let bot = Bot(json: body)
                completion(bot: bot, error: nil)
            } else {
                completion(bot: nil, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
    public func deleteBot(botId: String, revision: String, completion: (success: Bool, error: NSError?) -> ()) {
        
        let params = [
            "rev": revision,
            "bot": botId
        ]
        
        self.sendRequestWithMethod(.DELETE, endpoint: .Bots, params: params, query: nil, body: nil) { (response, body, error) -> () in

            if error != nil {
                completion(success: false, error: error)
                return
            }
            
            if let response = response {
                if response.statusCode == 204 {
                    completion(success: true, error: nil)
                } else {
                    completion(success: false, error: Errors.errorWithInfo("Wrong status code: \(response.statusCode)"))
                }
            } else {
                completion(success: false, error: Errors.errorWithInfo("Nil response"))
            }
        }
    }
    
    public func getBots(completion: (bots: [Bot]?, error: NSError?) -> ()) {
        
        self.sendRequestWithMethod(.GET, endpoint: .Bots, params: nil, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(bots: nil, error: error)
                return
            }
            
            if let body = (body as? NSDictionary)?["results"] as? NSArray {
                let bots: [Bot] = XcodeServerArray(body)
                completion(bots: bots, error: nil)
            } else {
                completion(bots: nil, error: Errors.errorWithInfo("Wrong data returned: \(body)"))
            }
        }
    }
    
    public func getIntegrations(botId: String, query: [String: String], completion: (integrations: [Integration]?, error: NSError?) -> ()) {
        
        let params = [
            "bot": botId
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Integrations, params: params, query: query, body: nil) { (response, body, error) -> () in

            if error != nil {
                completion(integrations: nil, error: error)
                return
            }
            
            if let body = (body as? NSDictionary)?["results"] as? NSArray {
                let integrations: [Integration] = XcodeServerArray(body)
                completion(integrations: integrations, error: nil)
            } else {
                completion(integrations: nil, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
            AKA "Integrate this bot now"
    
    :param: botId      MUST BE the full bot.id, cannot be bot.tinyId!
    */
    public func postIntegration(botId: String, completion: (integration: Integration?, error: NSError?) -> ()) {
        
        let params = [
            "bot": botId
        ]
        
        self.sendRequestWithMethod(.POST, endpoint: .Integrations, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(integration: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let integration = Integration(json: body)
                completion(integration: integration, error: nil)
            } else {
                completion(integration: nil, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
    public func cancelIntegration(integrationId: String, completion: (success: Bool, error: NSError?) -> ()) {
        
        let params = [
            "integration": integrationId
        ]
        
        self.sendRequestWithMethod(.POST, endpoint: .CancelIntegration, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(success: false, error: error)
                return
            }
            
            completion(success: true, error: nil)
        }
    }
    
    public func getDevices(completion: (devices: [Device]?, error: NSError?) -> ()) {
        
        self.sendRequestWithMethod(.GET, endpoint: .Devices, params: nil, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(devices: nil, error: error)
                return
            }
            
            if let array = (body as? NSDictionary)?["results"] as? NSArray {
                let devices: [Device] = XcodeServerArray(array)
                completion(devices: devices, error: error)
            } else {
                completion(devices: nil, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
    public func getUserCanCreateBots(completion: (canCreateBots: Bool, error: NSError?) -> ()) {
        
        self.sendRequestWithMethod(.GET, endpoint: .UserCanCreateBots, params: nil, query: nil, body: nil) { (response, body, error) -> () in

            if let error = error {
                completion(canCreateBots: false, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                if let canCreateBots = body["result"] as? Bool where canCreateBots == true {
                    completion(canCreateBots: true, error: nil)
                } else {
                    completion(canCreateBots: false, error: nil)
                }
            } else {
                completion(canCreateBots: false, error: Errors.errorWithInfo("Wrong body \(body)"))
            }
        }
    }
    
//    public func reportQueueSizeAndEstimatedWaitingTime(integration: Integration, completion: ((queueSize: Int, estWait: Double), NSError?) -> ()) {
    
    //TODO: we need to call getIntegrations() -> filter pending and running Integrations -> get unique bots of these integrations -> query for the average integration time of each bot -> estimate, based on the pending/running integrations, how long it will take for the passed in integration to finish
//    }
    
}
