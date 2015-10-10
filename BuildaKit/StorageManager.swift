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

public enum StorageManagerError: ErrorType {
    case DuplicateServerConfig(XcodeServerConfig)
    case DuplicateProjectConfig(ProjectConfig)
}

public class StorageManager {
    
    public let syncerConfigs = MutableProperty<[SyncerConfig]>([])
    public let serverConfigs = MutableProperty<[String: XcodeServerConfig]>([:])
    public let projectConfigs = MutableProperty<[String: ProjectConfig]>([:])
    public let buildTemplates = MutableProperty<[String: BuildTemplate]>([:])
    public let triggerConfigs = MutableProperty<[String: TriggerConfig]>([:])
    public let config = MutableProperty<[String: AnyObject]>([:])
    
    private var heartbeatManager: HeartbeatManager!
    
    public init() {
        self.loadAllFromPersistence()
        self.setupHeartbeatManager()
        self.setupSaving()
    }
    
    deinit {
        //
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
    
    
    public func addSyncer(syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool,
        projectConfig: ProjectConfig, serverConfig: XcodeServerConfig, watchedBranchNames: [String]) -> SyncerConfig? {
            
            //this function should already take a config
//            if syncInterval <= 0 {
//                Log.error("Sync interval must be > 0 seconds.")
//                return nil
//            }
//            
//            //TODO: move preferred build template from project here
//            
//            var syncerConfig = SyncerConfig()
//            syncerConfig.preferredTemplateRef = "" //TODO:
//            syncerConfig.projectRef = projectConfig.id
//            syncerConfig.xcodeServerRef = serverConfig.id
//            
//            
//            let syncerConfig = SyncerConfig(
//                preferredTemplateRef: "",
//                projectRef: projectRef,
//                xcodeServerRef: xcodeServerRef,
//                postStatusComments: postStatusComments,
//                syncInterval: syncInterval,
//                waitForLttm: waitForLttm,
//                watchedBranchNames: watchedBranchNames)
//            self.syncerConfigs.value.append(syncerConfig)
//            return syncerConfig
            return nil
    }
    
    //MARK: adding
    
    public func addTriggerConfig(triggerConfig: TriggerConfig) {
        self.triggerConfigs.value[triggerConfig.id] = triggerConfig
    }
    
    public func addBuildTemplate(buildTemplate: BuildTemplate) {
        self.buildTemplates.value[buildTemplate.id] = buildTemplate
    }
    
    public func addServerConfig(config: XcodeServerConfig) throws {
        
        //verify we don't have a duplicate
        let currentConfigs: [String: XcodeServerConfig] = self.serverConfigs.value
        let dup = currentConfigs
            .map { $0.1 }
            //find those matching host and username
            .filter { $0.host == config.host && $0.user == config.user }
            //but if it's an exact match (id), it's not a duplicate - it's identity
            .filter { $0.id != config.id }
            .first
        if let duplicate = dup {
            throw StorageManagerError.DuplicateServerConfig(duplicate)
        }
        
        //no duplicate, save!
        self.serverConfigs.value[config.id] = config
    }
    
    public func addProjectConfig(config: ProjectConfig) throws {
        
        //verify we don't have a duplicate
        let currentConfigs: [String: ProjectConfig] = self.projectConfigs.value
        let dup = currentConfigs
            .map { $0.1 }
            //find those matching local file url
            .filter { $0.url == config.url }
            //but if it's an exact match (id), it's not a duplicate - it's identity
            .filter { $0.id != config.id }
            .first
        if let duplicate = dup {
            throw StorageManagerError.DuplicateProjectConfig(duplicate)
        }
        
        //no duplicate, save!
        self.projectConfigs.value[config.id] = config
    }
    
    //MARK: removing
    
    public func removeTriggerConfig(triggerConfig: TriggerConfig) {
        self.triggerConfigs.value.removeValueForKey(triggerConfig.id)
    }
    
    public func removeBuildTemplate(buildTemplate: BuildTemplate) {
        self.buildTemplates.value.removeValueForKey(buildTemplate.id)
    }
    
    public func removeProjectConfig(projectConfig: ProjectConfig) {
        
        //TODO: make sure this project config is not owned by a project which
        //is running right now.
        self.projectConfigs.value.removeValueForKey(projectConfig.id)
    }
    
    public func removeServer(serverConfig: XcodeServerConfig) {
        
        //TODO: make sure this server config is not owned by a server which
        //is running right now.
        self.serverConfigs.value.removeValueForKey(serverConfig.id)
    }
    
    public func removeSyncer(syncer: HDGitHubXCBotSyncer) {
        
        //TODO: make sure this syncer config is not owned by a syncer which
        //is running right now.
        self.syncerConfigs.value.removeAll(keepCapacity: true)
    }
    
    //MARK: lookup
    
    public func triggerConfigsForIds(ids: [RefType]) -> [TriggerConfig] {
        
        let idsSet = Set(ids)
        return self.triggerConfigs.value.map { $0.1 }.filter { idsSet.contains($0.id) }
    }
    
    public func buildTemplatesForProjectName(projectName: String) -> SignalProducer<[BuildTemplate], NoError> {
        
        //filter all build templates with the project name || with no project name (legacy reasons)
        return self
            .buildTemplates
            .producer
            .map { Array($0.values) }
            .map {
                return $0.filter { (template: BuildTemplate) -> Bool in
                    if let templateProjectName = template.projectName {
                        return projectName == templateProjectName
                    } else {
                        //if it doesn't yet have a project name associated, assume we have to show it
                        return true
                    }
                }
        }
    }
    
    private func projectForRef(ref: RefType) -> ProjectConfig? {
        return self.projectConfigs.value[ref]
    }
    
    private func serverForHost(host: String) -> XcodeServer? {
        guard let config = self.serverConfigs.value[host] else { return nil }
        let server = XcodeServerFactory.server(config)
        return server
    }
    
    //MARK: loading
    
    private func loadAllFromPersistence() {
        
        self.config.value = Persistence.loadDictionaryFromFile("Config.json") ?? [:]
        let allProjects: [ProjectConfig] = Persistence.loadArrayFromFile("Projects.json") ?? []
        self.projectConfigs.value = allProjects.dictionarifyWithKey { $0.id }
        let allServerConfigs: [XcodeServerConfig] = Persistence.loadArrayFromFile("ServerConfigs.json") ?? []
        self.serverConfigs.value = allServerConfigs.dictionarifyWithKey { $0.id }
        let allTemplates: [BuildTemplate] = Persistence.loadArrayFromFolder("BuildTemplates") ?? []
        self.buildTemplates.value = allTemplates.dictionarifyWithKey { $0.id }
        let allTriggers: [TriggerConfig] = Persistence.loadArrayFromFolder("Triggers") ?? []
        self.triggerConfigs.value = allTriggers.dictionarifyWithKey { $0.id }
        self.syncerConfigs.value = Persistence.loadArrayFromFile("Syncers.json") { self.createSyncerConfigFromJSON($0) } ?? []
    }
    
    //MARK: Saving
    
    private func setupSaving() {
        
        //simple - save on every change after the initial bunch has been loaded!
        
        self.serverConfigs.producer.startWithNext {
            StorageManager.saveServerConfigs($0)
        }
        self.projectConfigs.producer.startWithNext {
            StorageManager.saveProjectConfigs($0)
        }
        self.config.producer.startWithNext {
            StorageManager.saveConfig($0)
        }
        self.syncerConfigs.producer.startWithNext {
            StorageManager.saveSyncerConfigs($0)
        }
        self.buildTemplates.producer.startWithNext {
            StorageManager.saveBuildTemplates($0)
        }
        self.triggerConfigs.producer.startWithNext {
            StorageManager.saveTriggerConfigs($0)
        }
    }
    
    private static func saveConfig(config: [String: AnyObject]) {
        Persistence.saveDictionary("Config.json", item: config)
    }
    
    private static func saveProjectConfigs(configs: [String: ProjectConfig]) {
        let projectConfigs: NSArray = Array(configs.values).map { $0.jsonify() }
        Persistence.saveArray("Projects.json", items: projectConfigs)
    }
    
    private static func saveServerConfigs(configs: [String: XcodeServerConfig]) {
        let serverConfigs = Array(configs.values).map { $0.jsonify() }
        Persistence.saveArray("ServerConfigs.json", items: serverConfigs)
    }
    
    private static func saveSyncerConfigs(configs: [SyncerConfig]) {
        let syncerConfigs = configs.map { $0.jsonify() }
        Persistence.saveArray("Syncers.json", items: syncerConfigs)
    }
    
    private static func saveBuildTemplates(templates: [String: BuildTemplate]) {
        
        //but first we have to *delete* the directory first.
        //think of a nicer way to do this, but this at least will always
        //be consistent.
        let folderName = "BuildTemplates"
        Persistence.deleteFolder(folderName)
        let items = Array(templates.values)
        Persistence.saveArrayIntoFolder(folderName, items: items) { $0.id }
    }
    
    private static func saveTriggerConfigs(configs: [String: TriggerConfig]) {
        
        //but first we have to *delete* the directory first.
        //think of a nicer way to do this, but this at least will always
        //be consistent.
        let folderName = "Triggers"
        Persistence.deleteFolder(folderName)
        let items = Array(configs.values)
        Persistence.saveArrayIntoFolder(folderName, items: items) { $0.id }
    }
}

//HACK: move to XcodeServerSDK
extension TriggerConfig: JSONReadable, JSONWritable {
    public func jsonify() -> NSDictionary {
        return self.dictionarify()
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
