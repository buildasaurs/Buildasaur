//
//  Device.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Device : XcodeServerEntity {
    
    public let name: String
    public let simulator: Bool
    public let osVersion: String
    public let deviceType: String
    public let connected: Bool
    
    public required init(json: NSDictionary) {
        
        self.name = json.stringForKey("name")
        self.simulator = json.boolForKey("simulator")
        self.osVersion = json.stringForKey("osVersion")
        self.deviceType = json.stringForKey("deviceType")
        self.connected = json.boolForKey("connected")
        
        super.init(json: json)
    }
    
    public override func dictionarify() -> NSDictionary {
        
        return [
            "device_id": self.id
        ]
    }
    
}
