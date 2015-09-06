//
//  GitHubServer+RAC.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 06/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa

extension GitHubServer {
    
    public func getUserRepos() -> SignalProducer<[Repo], NSError> {
        return SignalProducer({
            (observer, disposable) -> () in
            
            self.getUserRepos({ (repos, error) -> () in
                if let error = error {
                    sendError(observer, error)
                } else {
                    sendNext(observer, repos!)
                }
                sendCompleted(observer)
            })
        })
    }
}
