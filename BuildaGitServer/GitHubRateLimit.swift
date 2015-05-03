//
//  GitHubRateLimit.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 03/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public struct GitHubRateLimit {
    
    public let resetTime: Double
    public let limit: Int
    public let remaining: Int
    public let now: Double = NSDate().timeIntervalSince1970
    
    public func getReport() -> String {
        
        let resetInterval = 3600.0 //reset interval is 1 hour
        let startTime = self.resetTime - resetInterval
        let remainingTime = self.resetTime - self.now
        let consumed = self.limit - self.remaining
        let consumedTime = self.now - startTime
        let rateOfConsumption = Double(consumed) / consumedTime
        let rateOfConsumptionPretty = rateOfConsumption.clipTo(2)
        let maxRateOfConsumption = Double(self.limit) / resetInterval
        let maxRateOfConsumptionPretty = maxRateOfConsumption.clipTo(2)
        
        //how much faster we can be consuming requests before we hit the maximum rate of 5000/hour
        let extraRateOfConsumption = (maxRateOfConsumption - rateOfConsumption).clipTo(2)
        let usedRatePercent = (100.0 * rateOfConsumption / maxRateOfConsumption).clipTo(2)
        
        let report = "count: \(consumed)/\(self.limit), renews in \(Int(remainingTime)) seconds, rate: \(rateOfConsumptionPretty)/\(maxRateOfConsumptionPretty), using \(usedRatePercent)% of the allowed request rate."
        return report
    }
    
}
