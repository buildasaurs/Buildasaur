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
                
                sink.sendNext(.Checking)
                
                NetworkUtils.checkAvailabilityOfXcodeServerWithCurrentSettings(input, completion: { (success, error) -> () in
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if success {
                            sink.sendNext(.Succeeded)
                        } else {
                            sink.sendNext(.Failed(error))
                        }
                        sink.sendCompleted()
                    })
                })
            }
        }
    }
    
    public static func projectAvailability() -> Action<ProjectConfig, AvailabilityCheckState, NoError> {
        return Action {
            (input: ProjectConfig) -> SignalProducer<AvailabilityCheckState, NoError> in
            
            return SignalProducer { sink, _ in
                
                sink.sendNext(.Checking)
                
                var project: Project!
                do {
                    project = try Project(config: input)
                } catch {
                    sink.sendNext(.Failed(error))
                    return
                }
                
                NetworkUtils.checkAvailabilityOfServiceWithProject(project, completion: { (success, error) -> () in
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        if success {
                            sink.sendNext(.Succeeded)
                        } else {
                            sink.sendNext(.Failed(error))
                        }
                        sink.sendCompleted()
                    })
                })
            }
        }
    }
}
