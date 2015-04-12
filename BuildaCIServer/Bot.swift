//
//  Bot.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Bot : XcodeServerEntity {
    
    public let name: String
    public let configuration: BotConfiguration
    public let integrationsCount: Int!

    public required init(json: NSDictionary) {
        
        self.name = json.stringForKey("name")
        self.configuration = BotConfiguration(json: json.dictionaryForKey("configuration"))
        self.integrationsCount = json.intForKey("integration_counter")
        
        super.init(json: json)
    }
    
    /**
    *  Creating bots on the server. Needs dictionary representation.
    */
    public init(name: String, configuration: BotConfiguration) {
        
        self.name = name
        self.configuration = configuration
        self.integrationsCount = nil
        
        super.init()
    }

    public override func dictionarify() -> NSDictionary {
        
        var dictionary = NSMutableDictionary()
        
        //name
        dictionary["name"] = self.name
        
        //configuration
        dictionary["configuration"] = self.configuration.dictionarify()
        
        //others
        dictionary["type"] = 1 //magic more
        dictionary["requiresUpgrade"] = false
        dictionary["group"] = [
            "name": NSUUID().UUIDString
        ]
        
        return dictionary
    }
    
    func description() -> String {
        return "[Bot \(self.name)]"
    }
}


