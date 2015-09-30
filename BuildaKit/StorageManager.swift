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
    
    public let syncers = MutableProperty<[HDGitHubXCBotSyncer]>([])
    public let servers = MutableProperty<[String: XcodeServerConfig]>([:])
    public let projects = MutableProperty<[String: Project]>([:])
    public let buildTemplates = MutableProperty<[BuildTemplate]>([])
    public let config = MutableProperty<[String: AnyObject]>([:])
    
    private var heartbeatManager: HeartbeatManager!
    
    private init() {
        self.loadAllFromPersistence()
        self.setupHeartbeatManager()
    }
    
    deinit {
        self.stop()
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
    
    public func addProjectAtURL(url: NSURL) throws -> Project {
        
        _ = try Project.attemptToParseFromUrl(url)
        if let project = Project(url: url) {
            self.projects.value[project.urlString] = project
            return project
        }
        throw Error.withInfo("Attempt to parse succeeded but Project still wasn't created")
    }
    
    public func addServerConfig(host host: String, user: String?, password: String?) -> XcodeServerConfig {
        let config = try! XcodeServerConfig(host: host, user: user, password: password)
        self.servers.value[host] = config
        return config
    }
    
    public func addSyncer(syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool,
        project: Project, serverConfig: XcodeServerConfig, watchedBranchNames: [String]) -> HDGitHubXCBotSyncer? {

        if syncInterval <= 0 {
            Log.error("Sync interval must be > 0 seconds.")
            return nil
        }
        
        let xcodeServer = XcodeServerFactory.server(serverConfig)
        let github = GitHubFactory.server(project.githubToken)
        let syncer = HDGitHubXCBotSyncer(
            integrationServer: xcodeServer,
            sourceServer: github,
            project: project,
            syncInterval: syncInterval,
            waitForLttm: waitForLttm,
            postStatusComments: postStatusComments,
            watchedBranchNames: watchedBranchNames)
        self.syncers.value.append(syncer)
        return syncer
    }
    
    public func saveBuildTemplate(buildTemplate: BuildTemplate) {
        
        //in case we have a duplicate, replace
        var duplicateFound = false
        for (idx, temp) in self.buildTemplates.value.enumerate() {
            if temp.uniqueId == buildTemplate.uniqueId {
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
            if temp.uniqueId == buildTemplate.uniqueId {
                self.buildTemplates.value.removeAtIndex(idx)
                break
            }
        }
        
        //also delete the file
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        let id = buildTemplate.uniqueId
        let templateUrl = templatesFolderUrl.URLByAppendingPathComponent("\(id).json")
        do { try NSFileManager.defaultManager().removeItemAtURL(templateUrl) } catch {}
        
        //save
        self.saveBuildTemplates()
    }
    
    public func removeProject(project: Project) {
        self.projects.value.removeValueForKey(project.urlString)
    }
    
    public func removeServer(serverConfig: XcodeServerConfig) {
        self.servers.value.removeValueForKey(serverConfig.host)
    }
    
    public func removeSyncer(syncer: HDGitHubXCBotSyncer) {
        
        //don't know how to compare syncers yet
        self.syncers.value.removeAll(keepCapacity: true)
    }
    
    private func projectForPath(path: String) -> Project? {
        return self.projects.value[path]
    }
    
    private func serverForHost(host: String) -> XcodeServer? {
        guard let config = self.servers.value[host] else { return nil }
        let server = XcodeServerFactory.server(config)
        return server
    }
    
    public func loadAllFromPersistence() {
        
        self.config.value = Persistence.loadDictionaryFromFile("Config.json") ?? [:]
        let allProjects: [Project] = Persistence.loadArrayFromFile("Projects.json") ?? []
        self.projects.value = self.dictionarifyWithKey(allProjects) { $0.urlString }
        let allServerConfigs: [XcodeServerConfig] = Persistence.loadArrayFromFile("ServerConfigs.json") ?? []
        self.servers.value = self.dictionarifyWithKey(allServerConfigs) { $0.host }
        self.buildTemplates.value = Persistence.loadArrayFromFolder("BuildTemplates") ?? []
        self.syncers.value = Persistence.loadArrayFromFile("Syncers.json") { self.createSyncerFromJSON($0) } ?? []
    }
    
    private func dictionarifyWithKey<T>(array: [T], key: (item: T) -> String) -> [String: T] {
        var dict = [String: T]()
        array.forEach { dict[key(item: $0)] = $0 }
        return dict
    }
    
    public func saveConfig() {
        Persistence.saveDictionary("Config.json", item: self.config.value)
    }
    
    public func saveProjects() {
        Persistence.saveArray("Projects.json", items: Array(self.projects.value.values))
    }
    
    public func saveServers() {
        Persistence.saveArray("ServerConfigs.json", items: Array(self.servers.value.values))
    }
    
    public func saveSyncers() {
        Persistence.saveArray("Syncers.json", items: self.syncers.value)
    }
    
    func saveBuildTemplates() {
        Persistence.saveArrayIntoFolder("BuildTemplates", items: self.buildTemplates.value) { $0.uniqueId }
    }
    
    public func stop() {
        self.saveAll()
        self.stopSyncers()
    }
    
    public func saveAll() {
        //save to persistence
        
        self.saveConfig()
        self.saveServers()
        self.saveProjects()
        self.saveBuildTemplates()
        self.saveSyncers()
    }
    
    public func stopSyncers() {
        self.syncers.value.forEach { $0.active = false }
    }
    
    public func startSyncers() {
        self.syncers.value.forEach { $0.active = true }
    }
}

//Syncer Parsing
extension StorageManager {
    
    private func createSyncerFromJSON(json: NSDictionary) -> HDGitHubXCBotSyncer? {
        
        guard
            let xcodeServerHost = json.optionalStringForKey("server_host"),
            let xcodeServer = self.serverForHost(xcodeServerHost),
            let projectPath = json.optionalStringForKey("project_path"),
            let project = self.projectForPath(projectPath)
            else { return nil }
        
        let syncInterval = json.optionalDoubleForKey("sync_interval") ?? 15
        let githubServer = GitHubFactory.server(project.githubToken)
        let waitForLttm = json.optionalBoolForKey("wait_for_lttm") ?? false
        let postStatusComments = json.optionalBoolForKey("post_status_comments") ?? true
        let watchedBranchNames = json.optionalArrayForKey("watched_branches") as? [String] ?? []
        
        let syncer = HDGitHubXCBotSyncer(integrationServer: xcodeServer, sourceServer: githubServer, project: project, syncInterval: syncInterval, waitForLttm: waitForLttm, postStatusComments: postStatusComments, watchedBranchNames: watchedBranchNames)
        return syncer
    }
}

extension StorageManager: HeartbeatManagerDelegate {
    public func numberOfRunningSyncers() -> Int {
        return self.syncers.value.filter { $0.active }.count
    }
}
