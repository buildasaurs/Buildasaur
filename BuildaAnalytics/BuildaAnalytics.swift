//
//  BuildaAnalytics.swift
//  Buildasaur
//
//  Created by Wyatt McBain on 8/24/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

import Tapstream

// MARK: BuildaAnalyticsEvent

/**
    The BuildaAnalyticsEvent hold information regarding a analytics event.
    
    - event: The Tapstream event object
*/
public struct BuildaAnalyticsEvent {
    let event: TSEvent
    
    public init(funnel: AnalyticsFunnel, event: AnalyticsEvent) {
        self.event = {
            let event = TSEvent.eventWithName(event.analyticsString, oneTimeOnly: false)
            event.addValue(funnel.funnelString, forKey: "funnel")
            return event as! TSEvent
        }()
    }
}

// MARK: BuildaAnalytics

/**
    BuildaAnalytics handles the core responsibilities of our events package.
    Contains a single shared instance of BuildaAnalytics and sets up the configuration
    of Tapstream's Analytics SDK.
*/
public class BuildaAnalytics: NSObject {
    
    /**
        The shared BuildaAnalytics object. One should only be created, to prevent
        multiple Tapstream instances from being created.
    */
    public class var sharedInstance: BuildaAnalytics {
        struct Static {
            static let instance: BuildaAnalytics = BuildaAnalytics()
        }
        return Static.instance
    }
    
    /**
        While we don't want to track any identifying personal information, it's still
        logical to create unique identifiers for our users so we can determine patterns
        for different types of users.
    */
    private var uniqueRandomIdentifier: String {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let existingID = userDefaults.stringForKey("analytics-identifier") {
            return existingID
        }
        
        let newID = NSUUID().UUIDString
        userDefaults.setObject(newID, forKey: "analytics-identifier")
        return newID
    }
    
    
    // MARK: Initializers
    
    private override init() {
        super.init()
        self.setupAnalytics()
    }
    
    
    // MARK: Event Handlers
    
    /**
        Fires an analytics event and sends the information to Tapstream

        :param: event - The BuildaAnalytics event to be sent
    */
    public func fireAnalyticsEvent(event: BuildaAnalyticsEvent) {
        let tapstream = TSTapstream.instance()
        tapstream.fireEvent(event.event)
    }
    
    
    // MARK: Setup 
    
    /**
        Initializes our Analytics object with configuration settings to prevent
        tracking user identifying information.
    */
    private func setupAnalytics() {
        
        // Analytics Settings
        let accountName     =  "accountName"
        let accountSecret   =   "accountSecret"
        
        if let config = TSConfig.configWithDefaults() as? TSConfig {
            
            config.collectWifiMac               = false // disable default user tracking
            config.fireAutomaticInstallEvent    = false // disable install event
            config.fireAutomaticOpenEvent       = false // disable default open event
            config.fireAutomaticIAPEvents       = false // disable in app purchases
                            
            // Set user identifier.
            config.globalEventParams.setValue(self.uniqueRandomIdentifier, forKey: "user")
                 
            // Create Tapstream Analytics object
            TSTapstream.createWithAccountName(accountName, developerSecret: accountSecret, config: config)
        }
    }
}
