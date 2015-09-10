//
//  SyncerBotUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

extension HDGitHubXCBotSyncer {
    
    class func formattedDurationOfIntegration(integration: Integration) -> String? {
        
        if let seconds = integration.duration {
            
            let result = TimeUtils.secondsToNaturalTime(Int(seconds))
            return result
            
        } else {
            Log.error("No duration provided in integration \(integration)")
            return "[NOT PROVIDED]"
        }
    }
    
    class func baseCommentLinesFromIntegration(integration: Integration) -> [String] {
        
        var lines = [String]()
        
        lines.append("Result of Integration **\(integration.number)**")
        lines.append("---")
        
        if let duration = self.formattedDurationOfIntegration(integration) {
            lines.append("*Duration*: " + duration)
        }
        return lines
    }
    
}