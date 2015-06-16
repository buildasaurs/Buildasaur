//
//  BuildTemplate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 09/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK

private let kKeyUniqueId = "id"
private let kKeyName = "name"
private let kKeyScheme = "scheme"
private let kKeySchedule = "schedule"
private let kKeyCleaningPolicy = "cleaning_policy"
private let kKeyTriggers = "triggers"
private let kKeyTestingDevices = "testing_devices"
private let kKeyDestinationType = "destination_type"
private let kKeyShouldAnalyze = "should_analyze"
private let kKeyShouldTest = "should_test"
private let kKeyShouldArchive = "should_archive"

class BuildTemplate: JSONSerializable {
    
    var uniqueId: String //unique id of this build template, so that we can rename them easily
    var name: String?
    var scheme: String?
    var schedule: BotSchedule? //will be ignored for Synced bots, only useful for Manual creation. default: Manual
    var cleaningPolicy: BotConfiguration.CleaningPolicy
    var triggers: [Trigger]
    var shouldAnalyze: Bool?
    var shouldTest: Bool?
    var shouldArchive: Bool?
    var destinationType: BotConfiguration.TestingDestinationIdentifier
    var testingDeviceIds: [String]

    func validate() -> Bool {
        
        if count(self.uniqueId) == 0 { return false }
        if self.name == nil { return false }
        if self.scheme == nil { return false }
        //TODO: add all the other required values! this will be called on saving from the UI to make sure we have all the required fields.
        return true
    }
    
    init() {
        self.uniqueId = NSUUID().UUIDString
        self.name = "New Build Template Name"
        self.scheme = nil
        self.schedule = BotSchedule.manualBotSchedule()
        self.cleaningPolicy = BotConfiguration.CleaningPolicy.Never
        self.triggers = []
        self.destinationType = BotConfiguration.TestingDestinationIdentifier.AllCompatible
        self.shouldAnalyze = false
        self.shouldTest = false
        self.shouldArchive = false
        self.testingDeviceIds = []
    }
    
    required init?(json: NSDictionary) {
        
        self.uniqueId = json.optionalStringForKey(kKeyUniqueId) ?? ""
        self.name = json.optionalStringForKey(kKeyName)
        self.scheme = json.optionalStringForKey(kKeyScheme)
        if let scheduleDict = json.optionalDictionaryForKey(kKeySchedule) {
            self.schedule = BotSchedule(json: scheduleDict)
        } else {
            self.schedule = BotSchedule.manualBotSchedule()
        }
        if
            let cleaningPolicy = json.optionalIntForKey(kKeyCleaningPolicy),
            let policy = BotConfiguration.CleaningPolicy(rawValue: cleaningPolicy) {
                self.cleaningPolicy = policy
        } else {
            self.cleaningPolicy = BotConfiguration.CleaningPolicy.Never
        }
        if let array = (json.optionalArrayForKey(kKeyTriggers) as? [NSDictionary]) {
            self.triggers = array.map { Trigger(json: $0) }
        } else {
            self.triggers = []
        }
        if
            let destinationType = json.optionalIntForKey(kKeyDestinationType),
            let destination = BotConfiguration.TestingDestinationIdentifier(rawValue: destinationType){
            self.destinationType = destination
        } else {
            self.destinationType = .AllCompatible
        }
        self.shouldAnalyze = json.optionalBoolForKey(kKeyShouldAnalyze)
        self.shouldTest = json.optionalBoolForKey(kKeyShouldTest)
        self.shouldArchive = json.optionalBoolForKey(kKeyShouldArchive)
        self.testingDeviceIds = json.optionalArrayForKey(kKeyTestingDevices) as? [String] ?? []

        if !self.validate() {
            return nil
        }
    }
    
    func jsonify() -> NSDictionary {
        var dict = NSMutableDictionary()
        
        dict[kKeyUniqueId] = self.uniqueId
        dict[kKeyTriggers] = self.triggers.map({ $0.dictionarify() })
        dict[kKeyTestingDevices] = self.testingDeviceIds
        dict[kKeyCleaningPolicy] = self.cleaningPolicy.rawValue
        dict[kKeyDestinationType] = self.destinationType.rawValue
        dict.optionallyAddValueForKey(self.name, key: kKeyName)
        dict.optionallyAddValueForKey(self.scheme, key: kKeyScheme)
        dict.optionallyAddValueForKey(self.schedule?.dictionarify(), key: kKeySchedule)
        dict.optionallyAddValueForKey(self.shouldAnalyze, key: kKeyShouldAnalyze)
        dict.optionallyAddValueForKey(self.shouldTest, key: kKeyShouldTest)
        dict.optionallyAddValueForKey(self.shouldArchive, key: kKeyShouldArchive)
        
        return dict
    }
}
