//
//  Availability.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/6/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import BuildaUtils
import XcodeServerSDK

public class AvailabilityChecker {
    
    public static func xcodeServerAvailability() -> Action<XcodeServerConfig, AvailabilityCheckState, NoError> {
        return Action {
            (input: XcodeServerConfig) -> SignalProducer<AvailabilityCheckState, NoError> in
            
            return SignalProducer {
                sink, _ in
                
                sendNext(sink, .Checking)
                statusChanged(status: .Checking, done: false)
                NetworkUtils.checkAvailabilityOfXcodeServerWithCurrentSettings(config, completion: { (success, error) -> () in
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if success {
                            statusChanged(status: .Succeeded, done: true)
                        } else {
                            statusChanged(status: .Failed(error), done: true)
                        }
                    })
                })
            }
        }
    }
}
