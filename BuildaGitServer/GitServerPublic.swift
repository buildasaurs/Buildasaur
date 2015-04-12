//
//  GitSourcePublic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class GitServer {
    
    public typealias Completion = (response: NSHTTPURLResponse!, body: AnyObject?, error: NSError!) -> ()
    
    public init() {
        //initalize internal state
    }
    
    public func sendRequest(request: NSURLRequest, completion: Completion) {
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            //try to cast into HTTP response
            let httpResponse = response as NSHTTPURLResponse!
            
            if error != nil {
                
                //error in the networking stack
                completion(response: httpResponse, body: nil, error: error)
                return
            }
            
            if data == nil {
                
                //no body, but a valid response
                completion(response: httpResponse, body: nil, error: nil)
                return
            }
            
            //error is nil and data isn't, let's check the content type
            let contentType = httpResponse.allHeaderFields["Content-Type"] as String
            switch contentType {
                
            case "application/json; charset=utf-8":
                let (json: AnyObject!, error) = JSON.parse(data)
                completion(response: httpResponse, body: json, error: error)

            default:
                assertionFailure("Unrecognized content type \(contentType)")
            }
            
        }).resume()
    }
}

