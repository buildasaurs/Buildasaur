//
//  StorageManager.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import BuildaUtils
import XcodeServerSDK
import BuildaHeartbeatKit
import ReactiveCocoa

public class StorageManager {
    
    public static let sharedInstance = StorageManager()
    
    public let syncerConfigs = MutableProperty<[SyncerConfig]>([])
    public let serverConfigs = MutableProperty<[String: XcodeServerConfig]>([:])
    public let projectConfigs = MutableProperty<[String: ProjectConfig]>([:])
    public let buildTemplates = MutableProperty<[BuildTemplate]>([])
    public let config = MutableProperty<[String: AnyObject]>([:])
    
    private var heartbeatManager: HeartbeatManager!
    
    private init() {
        self.loadAllFromPersistence()
        self.setupHeartbeatManager()
    }
    
    deinit {
//        self.stop()
    }
    
    private func setupHeartbeatManager() {
        if let heartbeatOptOut = self.config.value["heartbeat_opt_out"] as? Bool where heartbeatOptOut {
            Log.info("User opted out of anonymous heartbeat")
        } else {
            Log.info("Will send anonymous heartbeat. To opt out add `\"heartbeat_opt_out\" = true` to ~/Library/Application Support/Buildasaur/Config.json")
            self.heartbeatManager = HeartbeatManager(server: "https://builda-ekg.herokuapp.com")
            self.heartbeatManager.delegate = self
            self.heartbeatManager.start()
        }
    }
    
    public func checkForProjectOrWorkspace(url: NSURL) throws {
        _ = try Project.attemptToParseFromUrl(url)
    }
    
    public func addServerConfig(host host: String, user: String?, password: String?) -> XcodeServerConfig {
        let config = try! XcodeServerConfig(host: host, user: user, password: password)
        self.serverConfigs.value[host] = config
        return config
    }
    
    public func addSyncer(syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool,
        projectConfig: ProjectConfig, serverConfig: XcodeServerConfig, watchedBranchNames: [String]) -> SyncerConfig? {
            
            if syncInterval <= 0 {
                Log.error("Sync interval must be > 0 seconds.")
                return nil
            }
            
            //TODO: move preferred build template from project here
            let projectRef = projectConfig.id
            let xcodeServerRef = serverConfig.id
            
            let syncerConfig = SyncerConfig(
                preferredTemplateRef: "",
                projectRef: projectRef,
                xcodeServerRef: xcodeServerRef,
                postStatusComments: postStatusComments,
                syncInterval: syncInterval,
                waitForLttm: waitForLttm,
                watchedBranchNames: watchedBranchNames)
            self.syncerConfigs.value.append(syncerConfig)
            return syncerConfig
    }
    
    public func saveBuildTemplate(buildTemplate: BuildTemplate) {
        
        //in case we have a duplicate, replace
        var duplicateFound = false
        for (idx, temp) in self.buildTemplates.value.enumerate() {
            if temp.id == buildTemplate.id {
                self.buildTemplates.value[idx] = buildTemplate
                duplicateFound = true
                break
            }
        }
        
        if !duplicateFound {
            self.buildTemplates.value.append(buildTemplate)
        }
        
        //now save all
        self.saveBuildTemplates()
    }
    
    public func removeBuildTemplate(buildTemplate: BuildTemplate) {
        
        //remove from the memory storage
        for (idx, temp) in self.buildTemplates.value.enumerate() {
            if temp.id == buildTemplate.id {
                self.buildTemplates.value.removeAtIndex(idx)
                break
            }
        }
        
        //also delete the file
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        let id = buildTemplate.id
        let templateUrl = templatesFolderUrl.URLByAppendingPathComponent("\(id).json")
        do { try NSFileManager.defaultManager().removeItemAtURL(templateUrl) } catch {}
        
        //save
        self.saveBuildTemplates()
    }
    
    public func buildTemplatesForProjectName(projectName: String) -> [BuildTemplate] {
        return self.buildTemplates.value.filter { (template: BuildTemplate) -> Bool in
            if let templateProjectName = template.projectName {
                return projectName == templateProjectName
            } else {
                //if it doesn't yet have a project name associated, assume we have to show it
                return true
            }
        }
    }
    
    public func removeProject(project: Project) {
        self.projectConfigs.value.removeValueForKey(project.urlString)
    }
    
    public func removeServer(serverConfig: XcodeServerConfig) {
        self.serverConfigs.value.removeValueForKey(serverConfig.host)
    }
    
    public func removeSyncer(syncer: HDGitHubXCBotSyncer) {
        
        //don't know how to compare syncers yet
        self.syncerConfigs.value.removeAll(keepCapacity: true)
    }
    
    private func projectForRef(ref: RefType) -> ProjectConfig? {
        return self.projectConfigs.value[ref]
    }
    
    private func serverForHost(host: String) -> XcodeServer? {
        guard let config = self.serverConfigs.value[host] else { return nil }
        let server = XcodeServerFactory.server(config)
        return server
    }
    
    public func loadAllFromPersistence() {
        
        self.config.value = Persistence.loadDictionaryFromFile("Config.json") ?? [:]
        let allProjects: [ProjectConfig] = Persistence.loadArrayFromFile("Projects.json") ?? []
        self.projectConfigs.value = allProjects.dictionarifyWithKey { $0.id }
        let allServerConfigs: [XcodeServerConfig] = Persistence.loadArrayFromFile("ServerConfigs.json") ?? []
        self.serverConfigs.value = allServerConfigs.dictionarifyWithKey { $0.id }
        self.buildTemplates.value = Persistence.loadArrayFromFolder("BuildTemplates") ?? []
        self.syncerConfigs.value = Persistence.loadArrayFromFile("Syncers.json") { self.createSyncerConfigFromJSON($0) } ?? []
    }
    
    public func saveConfig() {
        Persistence.saveDictionary("Config.json", item: self.config.value)
    }
    
    public func saveProjectConfigs() {
        let projectConfigs: NSArray = Array(self.projectConfigs.value.values).map { $0 as! AnyObject }
        Persistence.saveArray("Projects.json", items: projectConfigs)
    }
    
    public func saveServerConfigs() {
        let serverConfigs = Array(self.serverConfigs.value.values).map { $0 as! AnyObject }
        Persistence.saveArray("ServerConfigs.json", items: serverConfigs)
    }
    
    public func saveSyncerConfigs() {
        let syncerConfigs = self.syncerConfigs.value.map { $0 as! AnyObject }
        Persistence.saveArray("Syncers.json", items: syncerConfigs)
    }
    
    func saveBuildTemplates() {
        Persistence.saveArrayIntoFolder("BuildTemplates", items: self.buildTemplates.value) { $0.id }
    }
    
    public func saveAll() {
        //save to persistence
        
        self.saveConfig()
        self.saveServerConfigs()
        self.saveProjectConfigs()
        self.saveBuildTemplates()
        self.saveSyncerConfigs()
    }
    
}

//Syncer Parsing
extension StorageManager {
    
    private func createSyncerConfigFromJSON(json: NSDictionary) -> SyncerConfig? {
        
        do {
            return try SyncerConfig(json: json)
        } catch {
            Log.error(error)
        }
        return nil
    }
}

extension StorageManager: HeartbeatManagerDelegate {
    public func numberOfRunningSyncers() -> Int {
        //TODO: move this so the SyncerManager
        return -1
//        return self.syncerConfigs.value.filter { $0.active }.count
    }
}
