//
//  XcodeServerSyncerUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

public class XcodeServerSyncerUtils {
    
    public class func createBotFromBuildTemplate(botName: String, syncer: HDGitHubXCBotSyncer, template: BuildTemplate, project: Project, branch: String, scheduleOverride: BotSchedule?, xcodeServer: XcodeServer, completion: (bot: Bot?, error: NSError?) -> ()) {
        
        //pull info from template
        let schemeName = template.scheme!
        
        //optionally override the schedule, if nil, takes it from the template
        let schedule = scheduleOverride ?? template.schedule!
        let cleaningPolicy = template.cleaningPolicy
        let triggerIds = template.triggers
        let triggers = syncer.delegate!.syncer(syncer, triggersWithIds: triggerIds)
        let analyze = template.shouldAnalyze ?? false
        let test = template.shouldTest ?? false
        let archive = template.shouldArchive ?? false
        
        //TODO: create a device spec from testing devices and filter type (and scheme target type?)
        let testingDeviceIds = template.testingDeviceIds
        let filterType = template.deviceFilter
        let platformType = template.platformType ?? .iOS //default to iOS for no reason
        let architectureType = DeviceFilter.ArchitectureType.architectureFromPlatformType(platformType)
        
        let devicePlatform = DevicePlatform(type: platformType)
        let deviceFilter = DeviceFilter(platform: devicePlatform, filterType: filterType, architectureType: architectureType)
        
        let deviceSpecification = DeviceSpecification(filters: [deviceFilter], deviceIdentifiers: testingDeviceIds)
        
        let blueprint = project.createSourceControlBlueprint(branch)
        
        //create bot config
        let botConfiguration = BotConfiguration(
            builtFromClean: cleaningPolicy,
            analyze: analyze,
            test: test,
            archive: archive,
            schemeName: schemeName,
            schedule: schedule,
            triggers: triggers,
            deviceSpecification: deviceSpecification,
            sourceControlBlueprint: blueprint)
        
        //create the bot finally
        let newBot = Bot(name: botName, configuration: botConfiguration)
        
        xcodeServer.createBot(newBot, completion: { (response) -> () in
            
            var outBot: Bot?
            var outError: ErrorType?
            switch response {
            case .Success(let bot):
                //we good
                Log.info("Successfully created bot \(bot.name)")
                outBot = bot
                break
            case .Error(let error):
                outError = error
            default:
                outError = Error.withInfo("Failed to return bot after creation even after error was nil!")
            }
            
            //print success/failure etc
            if let error = outError {
                Log.error("Failed to create bot with name \(botName) and json \(newBot.dictionarify()), error \(error)")
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion(bot: outBot, error: outError as? NSError)
            })
        })
    }
    
}
