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
    public let servers = MutableProperty<[XcodeServerConfig]>([])
    public let projects = MutableProperty<[Project]>([])
    public let buildTemplates = MutableProperty<[BuildTemplate]>([])
    public let config = MutableProperty<[String: AnyObject]>([:])
    
    private var heartbeatManager: HeartbeatManager!
    
    init() {
        
        //initialize all stored Syncers
        self.loadAllFromPersistence()
        
        
        
        if let heartbeatOptOut = self.config["heartbeat_opt_out"] as? Bool where heartbeatOptOut {
            Log.info("User opted out of anonymous heartbeat")
        } else {
            Log.info("Will send anonymous heartbeat. To opt out add `\"heartbeat_opt_out\" = true` to ~/Library/Application Support/Buildasaur/Config.json")
            self.heartbeatManager = HeartbeatManager(server: "https://builda-ekg.herokuapp.com")
            self.heartbeatManager.delegate = self
            self.heartbeatManager.start()
        }
    }
    
    deinit {
        self.stop()
    }
    
    public func addProjectAtURL(url: NSURL) throws {
        
        _ = try Project.attemptToParseFromUrl(url)
        if let project = Project(url: url) {
            self.projects.append(project)
        } else {
            assertionFailure("Attempt to parse succeeded but Project still wasn't created")
        }
    }
    
    public func addServerConfig(host host: String, user: String?, password: String?) {
        let config = try! XcodeServerConfig(host: host, user: user, password: password)
        self.servers.append(config)
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
        self.syncers.append(syncer)
        return syncer
    }
    
    public func saveBuildTemplate(buildTemplate: BuildTemplate) {
        
        //in case we have a duplicate, replace
        var duplicateFound = false
        for (idx, temp) in self.buildTemplates.enumerate() {
            if temp.uniqueId == buildTemplate.uniqueId {
                self.buildTemplates[idx] = buildTemplate
                duplicateFound = true
                break
            }
        }
        
        if !duplicateFound {
            self.buildTemplates.append(buildTemplate)
        }
        
        //now save all
        self.saveBuildTemplates()
    }
    
    public func removeBuildTemplate(buildTemplate: BuildTemplate) {
        
        //remove from the memory storage
        for (idx, temp) in self.buildTemplates.enumerate() {
            if temp.uniqueId == buildTemplate.uniqueId {
                self.buildTemplates.removeAtIndex(idx)
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
        
        for (idx, p) in self.projects.enumerate() {
            if project.url == p.url {
                self.projects.removeAtIndex(idx)
                return
            }
        }
    }
    
    public func removeServer(serverConfig: XcodeServerConfig) {
        
        for (idx, p) in self.servers.enumerate() {
            if serverConfig.host == p.host {
                self.servers.removeAtIndex(idx)
                return
            }
        }
    }
    
    public func removeSyncer(syncer: HDGitHubXCBotSyncer) {
        
        //don't know how to compare syncers yet
        self.syncers.value.removeAll(keepCapacity: true)
    }
    
    public func loadAllFromPersistence() {
        
        self.config.value = Persistence.loadDictionaryFromFile("Config.json") ?? [:]
        self.projects.value = Persistence.loadArrayFromFile("Projects.json") ?? []
        self.servers.value = Persistence.loadArrayFromFile("ServerConfigs.json") ?? []
        self.buildTemplates.value = Persistence.loadArrayFromFile("BuildTemplates") ?? []
        self.syncers.value = Persistence.loadArrayFromFile("Syncers.json") {
            HDGitHubXCBotSyncer(json: $0, storageManager: self)
            } ?? []
    }
    
    
    public func saveConfig() {
        let configUrl = Persistence.getFileInAppSupportWithName("Config.json", isDirectory: false)
        let json = self.config
        do {
            try Persistence.saveJSONToUrl(json, url: configUrl)
        } catch {
            assert(false, "Failed to save Config, \(error)")
        }
    }
    
    public func saveProjects() {
        
        let projectsUrl = Persistence.getFileInAppSupportWithName("Projects.json", isDirectory: false)
        let jsons = self.projects.map { $0.jsonify() }
        do {
            try Persistence.saveJSONToUrl(jsons, url: projectsUrl)
        } catch {
            assert(false, "Failed to save Projects, \(error)")
        }
    }
    
    public func saveServers() {
        
        let serversUrl = Persistence.getFileInAppSupportWithName("ServerConfigs.json", isDirectory: false)
        let jsons = self.servers.map { $0.jsonify() }
        do {
            try Persistence.saveJSONToUrl(jsons, url: serversUrl)
        } catch {
            assert(false, "Failed to save ServerConfigs, \(error)")
        }
    }
    
    public func saveSyncers() {

        let syncersUrl = Persistence.getFileInAppSupportWithName("Syncers.json", isDirectory: false)
        let jsons = self.syncers.map { $0.jsonify() }
        do {
            try Persistence.saveJSONToUrl(jsons, url: syncersUrl)
        } catch {
            assert(false, "Failed to save Syncers, \(error)")
        }
    }
    
    public func saveBuildTemplates() {
        
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        self.buildTemplates.forEach {
            (template: BuildTemplate) -> () in
            
            let json = template.jsonify()
            let id = template.uniqueId
            let templateUrl = templatesFolderUrl.URLByAppendingPathComponent("\(id).json")
            do {
                try Persistence.saveJSONToUrl(json, url: templateUrl)
            } catch {
                assert(false, "Failed to save a Build Template, \(error)")
            }
        }
    }
    
    public func stop() {
        self.saveAll()
        self.stopSyncers()
    }
    
    public func saveAll() {
        //save to persistence
        
        self.saveConfig()
        self.saveProjects()
        self.saveServers()
        self.saveBuildTemplates()
        self.saveSyncers()
    }
    
    public func stopSyncers() {
        
        for syncer in self.syncers {
            syncer.active = false
        }
    }
    
    public func startSyncers() {
        //start all syncers in memory
        
        for syncer in self.syncers {
            syncer.active = true
        }
    }
}

extension StorageManager: HeartbeatManagerDelegate {
    public func numberOfRunningSyncers() -> Int {
        return self.syncers.filter { $0.active }.count
    }
}
