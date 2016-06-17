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

private let kKeyId = "id"
private let kKeyProjectName = "project_name"
private let kKeyName = "name"
private let kKeyScheme = "scheme"
private let kKeySchedule = "schedule"
private let kKeyCleaningPolicy = "cleaning_policy"
private let kKeyTriggers = "triggers"
private let kKeyTestingDevices = "testing_devices"
private let kKeyDeviceFilter = "device_filter"
private let kKeyPlatformType = "platform_type"
private let kKeyShouldAnalyze = "should_analyze"
private let kKeyShouldTest = "should_test"
private let kKeyShouldArchive = "should_archive"

public struct BuildTemplate: JSONSerializable {
    
    public let id: RefType
    
    public var projectName: String?
    public var name: String
    public var scheme: String
    public var schedule: BotSchedule
    public var cleaningPolicy: BotConfiguration.CleaningPolicy
    public var triggers: [RefType]
    public var shouldAnalyze: Bool
    public var shouldTest: Bool
    public var shouldArchive: Bool
    public var testingDeviceIds: [String]
    public var deviceFilter: DeviceFilter.FilterType
    public var platformType: DevicePlatform.PlatformType?
    
    func validate() -> Bool {
        
        if self.id.isEmpty { return false }
        //TODO: add all the other required values! this will be called on saving from the UI to make sure we have all the required fields.
        return true
    }
    
    public init(projectName: String? = nil) {
        self.id = Ref.new()
        self.projectName = projectName
        self.name = ""
        self.scheme = ""
        self.schedule = BotSchedule.manualBotSchedule()
        self.cleaningPolicy = BotConfiguration.CleaningPolicy.Never
        self.triggers = []
        self.shouldAnalyze = true
        self.shouldTest = true
        self.shouldArchive = false
        self.testingDeviceIds = []
        self.deviceFilter = .AllAvailableDevicesAndSimulators
        self.platformType = nil
    }
    
    public init(json: NSDictionary) throws {
        
        self.id = json.optionalStringForKey(kKeyId) ?? Ref.new()
        self.projectName = json.optionalStringForKey(kKeyProjectName)
        self.name = try json.stringForKey(kKeyName)
        self.scheme = try json.stringForKey(kKeyScheme)
        if let scheduleDict = json.optionalDictionaryForKey(kKeySchedule) {
            self.schedule = try BotSchedule(json: scheduleDict)
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
        if let array = (json.optionalArrayForKey(kKeyTriggers) as? [RefType]) {
            self.triggers = array
        } else {
            self.triggers = []
        }

        self.shouldAnalyze = try json.boolForKey(kKeyShouldAnalyze)
        self.shouldTest = try json.boolForKey(kKeyShouldTest)
        self.shouldArchive = try json.boolForKey(kKeyShouldArchive)
        
        self.testingDeviceIds = json.optionalArrayForKey(kKeyTestingDevices) as? [String] ?? []
        
        if
            let deviceFilterInt = json.optionalIntForKey(kKeyDeviceFilter),
            let deviceFilter = DeviceFilter.FilterType(rawValue: deviceFilterInt)
        {
            self.deviceFilter = deviceFilter
        } else {
            self.deviceFilter = .AllAvailableDevicesAndSimulators
        }
        
        if
            let platformTypeString = json.optionalStringForKey(kKeyPlatformType),
            let platformType = DevicePlatform.PlatformType(rawValue: platformTypeString) {
                self.platformType = platformType
        } else {
            self.platformType = nil
        }
        
        if !self.validate() {
            throw Error.withInfo("Invalid input into Build Template")
        }
    }
    
    public func jsonify() -> NSDictionary {
        let dict = NSMutableDictionary()
        
        dict[kKeyId] = self.id
        dict[kKeyTriggers] = self.triggers
        dict[kKeyDeviceFilter] = self.deviceFilter.rawValue
        dict[kKeyTestingDevices] = self.testingDeviceIds ?? []
        dict[kKeyCleaningPolicy] = self.cleaningPolicy.rawValue
        dict[kKeyName] = self.name
        dict[kKeyScheme] = self.scheme
        dict[kKeyShouldAnalyze] = self.shouldAnalyze
        dict[kKeyShouldTest] = self.shouldTest
        dict[kKeyShouldArchive] = self.shouldArchive
        dict[kKeySchedule] = self.schedule.dictionarify()
        dict.optionallyAddValueForKey(self.projectName, key: kKeyProjectName)
        dict.optionallyAddValueForKey(self.platformType?.rawValue, key: kKeyPlatformType)
        
        return dict
    }
}
