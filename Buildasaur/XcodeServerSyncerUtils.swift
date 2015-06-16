//
//  XcodeServerSyncerUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

class XcodeServerSyncerUtils {
    
    class func createBotFromBuildTemplate(botName: String, template: BuildTemplate, project: LocalSource, branch: String, scheduleOverride: BotSchedule?, xcodeServer: XcodeServer, completion: (bot: Bot?, error: NSError?) -> ()) {
        
        //pull info from template
        let schemeName = template.scheme!
        
        //optionally override the schedule, if nil, takes it from the template
        let schedule = scheduleOverride ?? template.schedule!
        let cleaningPolicy = template.cleaningPolicy
        let triggers = template.triggers
        let testingDeviceIDs = template.testingDeviceIds
        let testingDestinationType = template.destinationType
        let analyze = template.shouldAnalyze ?? false
        let test = template.shouldTest ?? false
        let archive = template.shouldArchive ?? false
        let blueprint = project.createSourceControlBlueprint(branch)
        
        //create bot config
        let botConfiguration = BotConfiguration(builtFromClean: cleaningPolicy,
            analyze: analyze, test: test, archive: archive, schemeName: schemeName, schedule: schedule,
            triggers: triggers, testingDeviceIDs: testingDeviceIDs, testingDestinationType:testingDestinationType, sourceControlBlueprint: blueprint)
        
        //create the bot finally
        let newBot = Bot(name: botName, configuration: botConfiguration)
        
        xcodeServer.createBot(newBot, completion: { (bot, error) -> () in
            
            var outError: NSError?
            //print success/failure etc
            if let error = error {
                outError = error
                Log.error("Failed to create bot with name \(botName) and json \(newBot.dictionarify()), error \(error)")
            } else if let bot = bot {
                Log.info("Successfully created bot \(bot.name)")
            } else {
                outError = Error.withInfo("Failed to return bot after creation even after error was nil!")
                Log.error(outError?.description ?? "")
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion(bot: bot, error: outError)
            })
        })
    }
    
}
