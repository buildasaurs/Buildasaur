//
//  SimpleURLCache.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/19/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import SwiftSafe

class ResponseInfo: AnyObject {
    let response: NSHTTPURLResponse
    let body: AnyObject?
    
    init(response: NSHTTPURLResponse, body: AnyObject?) {
        self.response = response
        self.body = body
    }
}

struct CachedInfo {
    let responseInfo: ResponseInfo?
    let update: (ResponseInfo) -> ()
    
    var etag: String? {
        guard let responseInfo = self.responseInfo else { return nil }
        return responseInfo.response.allHeaderFields["ETag"] as? String
    }
}

protocol URLCache {
    func getCachedInfoForRequest(request: NSURLRequest) -> CachedInfo
}

/**
 *  Stores responses in memory only and only if resp code was in range 200...299
 *  This is optimized for APIs that return ETag for every response, thus
 *  a repeated request can send over ETag in a header, allowing for not
 *  downloading data again. In the case of GitHub, such request doesn't count
 *  towards the rate limit.
 */
class InMemoryURLCache: URLCache {
    
    private let storage = NSCache()
    private let safe: Safe = CREW()
    
    init() {
        self.storage.countLimit = 50
    }
    
    func getCachedInfoForRequest(request: NSURLRequest) -> CachedInfo {
        
        var responseInfo: ResponseInfo?
        let key = request.cacheableKey()
        self.safe.read {
            responseInfo = self.storage.objectForKey(key) as? ResponseInfo
        }
        
        let info = CachedInfo(responseInfo: responseInfo) { (responseInfo) -> () in
            self.safe.write {
                self.storage.setObject(responseInfo, forKey: key)
            }
        }
        return info
    }
}

extension NSURLRequest {
    func cacheableKey() -> String {
        return "\(self.HTTPMethod!)-\(self.URL!.absoluteString)"
    }
}

