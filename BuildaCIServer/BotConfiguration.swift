//
//  BotConfiguration.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class BotConfiguration : XcodeServerEntity {
    
    public enum CleaningPolicy : Int {
        case Never = 0
        case Always
        case Once_a_Day
        case Once_a_Week
        
        public func toString() -> String {
            switch self {
            case .Never:
                return "Never"
            case .Always:
                return "Always"
            case .Once_a_Day:
                return "Once a day (first build)"
            case .Once_a_Week:
                return "Once a week (first build)"
            }
        }
    }
    
    public enum DeviceType : String {
        case Simulator = "com.apple.iphone-simulator"
        case Mac = "com.apple.mac"
        case iPhone = "com.apple.iphone" //also includes iPad and iPod Touch
    }
    
    public enum TestingDestinationIdentifier : Int {
        case iOS_AllDevicesAndSimulators = 0 //iOS default - for build only
        case iOS_AllDevices = 1
        case iOS_AllSimulators = 2
        case iOS_SelectedDevicesAndSimulators = 3
        case Mac = 7 //Mac default (probably, crashes when saving in Xcode) - for build only
        case AllCompatible = 8 //All Compatible default - for build only
        
        public func toString() -> String {
            switch self {
            case .iOS_AllDevicesAndSimulators:
                return "iOS: All Devices and Simulators"
            case .iOS_AllDevices:
                return "iOS: All Devices"
            case .iOS_AllSimulators:
                return "iOS: All Simulators"
            case .iOS_SelectedDevicesAndSimulators:
                return "iOS: Selected Devices and Simulators"
            case .Mac:
                return "Mac"
            case .AllCompatible:
                return "All Compatible (Mac + iOS)"
            }
        }
        
        public func allowedDeviceTypes() -> [DeviceType] {
            switch self {
            case .iOS_AllDevicesAndSimulators:
                return [.iPhone, .Simulator]
            case .iOS_AllDevices:
                return [.iPhone]
            case .iOS_AllSimulators:
                return [.Simulator]
            case .iOS_SelectedDevicesAndSimulators:
                return [.iPhone, .Simulator]
            case .Mac:
                return [.Mac]
            case .AllCompatible:
                return [.iPhone, .Simulator, .Mac]
            }
        }
    }
    
    public let builtFromClean: CleaningPolicy!
    public let analyze: Bool
    public let test: Bool
    public let archive: Bool
    public let schemeName: String
    public let schedule: BotSchedule
    public let triggers: [Trigger]
    public let testingDestinationType: TestingDestinationIdentifier?
    public let testingDeviceIDs: [String]
    public let sourceControlBlueprint: SourceControlBlueprint
    
    public required init(json: NSDictionary) {
        
        self.builtFromClean = CleaningPolicy(rawValue: json.intForKey("builtFromClean"))
        self.analyze = json.boolForKey("performsAnalyzeAction")
        self.archive = json.boolForKey("performsArchiveAction")
        self.test = json.boolForKey("performsTestAction")
        self.schemeName = json.stringForKey("schemeName")
        self.schedule = BotSchedule(json: json)
        self.triggers = XcodeServerArray(json.arrayForKey("triggers"))
        self.testingDestinationType = TestingDestinationIdentifier(rawValue: json.intForKey("testingDestinationType"))
        self.testingDeviceIDs = json.arrayForKey("testingDeviceIDs")
        self.sourceControlBlueprint = SourceControlBlueprint(json: json.dictionaryForKey("sourceControlBlueprint"))
        
        super.init(json: json)
    }
    
    public init(
        builtFromClean: CleaningPolicy,
        analyze: Bool,
        test: Bool,
        archive: Bool,
        schemeName: String,
        schedule: BotSchedule,
        triggers: [Trigger],
        testingDeviceIDs: [String],
        testingDestinationType: TestingDestinationIdentifier,
        sourceControlBlueprint: SourceControlBlueprint) {
            
            self.builtFromClean = builtFromClean
            self.analyze = analyze
            self.test = test
            self.archive = archive
            self.schemeName = schemeName
            self.schedule = schedule
            self.triggers = triggers
            self.testingDeviceIDs = testingDeviceIDs
            self.sourceControlBlueprint = sourceControlBlueprint
            self.testingDestinationType = testingDestinationType
            
            super.init()
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dictionary = NSMutableDictionary()
        
        //blueprint
        dictionary["sourceControlBlueprint"] = self.sourceControlBlueprint.dictionarify()
        
        //others
        dictionary["builtFromClean"] = self.builtFromClean.rawValue
        dictionary["performsTestAction"] = self.test
        dictionary["triggers"] = self.triggers.map { $0.dictionarify() }
        dictionary["performsAnalyzeAction"] = self.analyze
        dictionary["schemeName"] = self.schemeName
        dictionary["testingDeviceIDs"] = self.testingDeviceIDs
        dictionary["performsArchiveAction"] = self.archive
        dictionary["testingDestinationType"] = self.testingDestinationType?.rawValue //TODO: figure out if we need this
        
        let botScheduleDict = self.schedule.dictionarify() //needs to be merged into the main bot config dict
        dictionary.addEntriesFromDictionary(botScheduleDict as! [NSObject : AnyObject])
        
        return dictionary
    }
}

public class EmailConfiguration : XcodeServerEntity {
    
    public let additionalRecipients: [String]
    public let emailCommitters: Bool
    public let includeCommitMessages: Bool
    public let includeIssueDetails: Bool
    
    public init?(additionalRecipients: [String], emailCommitters: Bool, includeCommitMessages: Bool, includeIssueDetails: Bool) {
        
        self.additionalRecipients = additionalRecipients
        self.emailCommitters = emailCommitters
        self.includeCommitMessages = includeCommitMessages
        self.includeIssueDetails = includeIssueDetails
        
        super.init()
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        
        dict["emailCommitters"] = self.emailCommitters
        dict["includeCommitMessages"] = self.includeCommitMessages
        dict["includeIssueDetails"] = self.includeIssueDetails
        dict["additionalRecipients"] = self.additionalRecipients
        
        return dict
    }
    
    public required init(json: NSDictionary) {
        
        self.emailCommitters = json.boolForKey("emailCommitters")
        self.includeCommitMessages = json.boolForKey("includeCommitMessages")
        self.includeIssueDetails = json.boolForKey("includeIssueDetails")
        self.additionalRecipients = json.arrayForKey("additionalRecipients")
        
        super.init(json: json)
    }
}

public class TriggerConditions : XcodeServerEntity {
    
    public let onAnalyzerWarnings: Bool
    public let onBuildErrors: Bool
    public let onFailingTests: Bool
    public let onInternalErrors: Bool
    public let onSuccess: Bool
    public let onWarnings: Bool
    
    public init(onAnalyzerWarnings: Bool, onBuildErrors: Bool, onFailingTests: Bool, onInternalErrors: Bool, onSuccess: Bool, onWarnings: Bool) {
        
        self.onAnalyzerWarnings = onAnalyzerWarnings
        self.onBuildErrors = onBuildErrors
        self.onFailingTests = onFailingTests
        self.onInternalErrors = onInternalErrors
        self.onSuccess = onSuccess
        self.onWarnings = onWarnings
        
        super.init()
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        
        dict["onAnalyzerWarnings"] = self.onAnalyzerWarnings
        dict["onBuildErrors"] = self.onBuildErrors
        dict["onFailingTests"] = self.onFailingTests
        dict["onInternalErrors"] = self.onInternalErrors
        dict["onSuccess"] = self.onSuccess
        dict["onWarnings"] = self.onWarnings
        
        return dict
    }
    
    public required init(json: NSDictionary) {
        
        self.onAnalyzerWarnings = json.boolForKey("onAnalyzerWarnings")
        self.onBuildErrors = json.boolForKey("onBuildErrors")
        self.onFailingTests = json.boolForKey("onFailingTests")
        self.onInternalErrors = json.boolForKey("onInternalErrors")
        self.onSuccess = json.boolForKey("onSuccess")
        self.onWarnings = json.boolForKey("onWarnings")
        
        super.init(json: json)
    }
}

public class Trigger : XcodeServerEntity {
    
    public enum Phase: Int {
        case Prebuild = 1
        case Postbuild
        
        public func toString() -> String {
            switch self {
            case .Prebuild:
                return "Run Before the Build"
            case .Postbuild:
                return "Run After the Build"
            }
        }
    }
    
    public enum Kind: Int {
        case RunScript = 1
        case EmailNotification
        
        public func toString() -> String {
            switch self {
            case .RunScript:
                return "Run Script"
            case .EmailNotification:
                return "Send Email"
            }
        }
    }
    
    public let phase: Phase
    public let kind: Kind
    public let scriptBody: String
    public let name: String
    public let conditions: TriggerConditions?
    public let emailConfiguration: EmailConfiguration?
    
    public let uniqueId: String //only for in memory manipulation, don't persist anywhere
    
    public init?(phase: Phase, kind: Kind, scriptBody: String?, name: String?,
        conditions: TriggerConditions?, emailConfiguration: EmailConfiguration?) {

            self.phase = phase
            self.kind = kind
            self.scriptBody = scriptBody ?? ""
            self.name = name ?? kind.toString()
            self.conditions = conditions
            self.emailConfiguration = emailConfiguration
            self.uniqueId = NSUUID().UUIDString
            
            super.init()

            //post build triggers must have conditions
            if phase == Phase.Postbuild {
                if conditions == nil {
                    return nil
                }
            }
            
            //email type must have a configuration
            if kind == Kind.EmailNotification {
                if emailConfiguration == nil {
                    return nil
                }
            }
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dict = NSMutableDictionary()
        
        dict["phase"] = self.phase.rawValue
        dict["type"] = self.kind.rawValue
        dict["scriptBody"] = self.scriptBody
        dict["name"] = self.name
        dict.optionallyAddValueForKey(self.conditions?.dictionarify(), key: "conditions")
        dict.optionallyAddValueForKey(self.emailConfiguration?.dictionarify(), key: "emailConfiguration")
        
        return dict
    }
    
    public required init(json: NSDictionary) {
        
        let phase = Phase(rawValue: json.intForKey("phase"))!
        self.phase = phase
        if let conditionsJSON = json.optionalDictionaryForKey("conditions") where phase == .Postbuild {
            //also parse conditions
            self.conditions = TriggerConditions(json: conditionsJSON)
        } else {
            self.conditions = nil
        }
        
        let kind = Kind(rawValue: json.intForKey("type"))!
        self.kind = kind
        if let configurationJSON = json.optionalDictionaryForKey("emailConfiguration") where kind == .EmailNotification {
            //also parse email config
            self.emailConfiguration = EmailConfiguration(json: configurationJSON)
        } else {
            self.emailConfiguration = nil
        }
        
        self.name = json.stringForKey("name")
        self.scriptBody = json.stringForKey("scriptBody")
        
        self.uniqueId = NSUUID().UUIDString

        super.init(json: json)
    }
}


public class BotSchedule : XcodeServerEntity {
    
    public enum Schedule : Int {
        
        case Periodical = 1
        case Commit
        case Manual
        
        public func toString() -> String {
            switch self {
            case .Periodical:
                return "Periodical"
            case .Commit:
                return "On Commit"
            case .Manual:
                return "Manual"
            }
        }
    }
    
    public enum Period : Int {
        case Hourly = 1
        case Daily
        case Weekly
    }
    
    public enum Day : Int {
        case Monday = 1
        case Tuesday
        case Wednesday
        case Thursday
        case Friday
        case Saturday
        case Sunday
    }
    
    public let schedule: Schedule!
    
    public let period: Period?
    
    public let day: Day!
    public let hours: Int!
    public let minutes: Int!
    
    public required init(json: NSDictionary) {
        
        let schedule = Schedule(rawValue: json.intForKey("scheduleType"))!
        self.schedule = schedule
        
        if schedule == .Periodical {
            
            let period = Period(rawValue: json.intForKey("periodicScheduleInterval"))!
            self.period = period
            
            let minutes = json.optionalIntForKey("minutesAfterHourToIntegrate")
            let hours = json.optionalIntForKey("hourOfIntegration")
            
            switch period {
            case .Hourly:
                self.minutes = minutes!
                self.hours = nil
                self.day = nil
            case .Daily:
                self.minutes = minutes!
                self.hours = hours!
                self.day = nil
            case .Weekly:
                self.minutes = minutes!
                self.hours = hours!
                self.day = Day(rawValue: json.intForKey("weeklyScheduleDay"))
            }
        } else {
            self.period = nil
            self.minutes = nil
            self.hours = nil
            self.day = nil
        }
        
        super.init(json: json)
    }
    
    private init(schedule: Schedule, period: Period?, day: Day?, hours: Int?, minutes: Int?) {
        
        self.schedule = schedule
        self.period = period
        self.day = day
        self.hours = hours
        self.minutes = minutes
        
        super.init()
    }
    
    public class func manualBotSchedule() -> BotSchedule {
        return BotSchedule(schedule: .Manual, period: nil, day: nil, hours: nil, minutes: nil)
    }

    public class func commitBotSchedule() -> BotSchedule {
        return BotSchedule(schedule: .Commit, period: nil, day: nil, hours: nil, minutes: nil)
    }
    
    public override func dictionarify() -> NSDictionary {
        
        var dictionary = NSMutableDictionary()
        
        dictionary["scheduleType"] = self.schedule.rawValue
        dictionary["periodicScheduleInterval"] = self.period?.rawValue ?? 0
        dictionary["weeklyScheduleDay"] = self.day?.rawValue ?? 0
        dictionary["hourOfIntegration"] = self.hours ?? 0
        dictionary["minutesAfterHourToIntegrate"] = self.minutes ?? 0
        
        return dictionary
    }
    
}

