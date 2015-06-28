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

//TODO: dump logs to a file (Cocoa Lumberjack?) in Application Support, so that people can send it for debugging

class StorageManager {
    
    static let sharedInstance = StorageManager()
    
    private(set) var syncers: [HDGitHubXCBotSyncer] = []
    private(set) var servers: [XcodeServerConfig] = []
    private(set) var projects: [LocalSource] = []
    private(set) var buildTemplates: [BuildTemplate] = []
    
    init() {
        
        //initialize all stored Syncers
        self.loadAllFromPersistence()
    }
    
    deinit {
        self.stop()
    }
    
    func addProjectAtURL(url: NSURL) -> (Bool, NSError?) {
        
        let (success, _, error) = LocalSource.attemptToParseFromUrl(url)
        if success {
            if let localSource = LocalSource(url: url) {
                
                self.projects.append(localSource)
                return (true, nil)
            } else {
                assertionFailure("Attempt to parse succeeded but LocalSource still wasn't created")
            }
        }
        return (false, error)
    }
    
    func addServerConfig(host host: String, user: String?, password: String?) {
        let config = try! XcodeServerConfig(host: host, user: user, password: password)
        self.servers.append(config)
    }
    
    func addSyncer(syncInterval: NSTimeInterval, waitForLttm: Bool, postStatusComments: Bool,
        project: LocalSource, serverConfig: XcodeServerConfig, watchedBranchNames: [String]) -> HDGitHubXCBotSyncer? {

        if syncInterval <= 0 {
            Log.error("Sync interval must be > 0 seconds.")
            return nil
        }
        
        let xcodeServer = XcodeServerFactory.server(serverConfig)
        let github = GitHubFactory.server(project.githubToken)
        let syncer = HDGitHubXCBotSyncer(
            integrationServer: xcodeServer,
            sourceServer: github,
            localSource: project,
            syncInterval: syncInterval,
            waitForLttm: waitForLttm,
            postStatusComments: postStatusComments,
            watchedBranchNames: watchedBranchNames)
        self.syncers.append(syncer)
        return syncer
    }
    
    func saveBuildTemplate(buildTemplate: BuildTemplate) {
        
        //in case we have a duplicate, replace
        var duplicateFound = false
        for (idx, temp) in enumerate(self.buildTemplates) {
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
    
    func removeBuildTemplate(buildTemplate: BuildTemplate) {
        
        //remove from the memory storage
        for (idx, temp) in enumerate(self.buildTemplates) {
            if temp.uniqueId == buildTemplate.uniqueId {
                self.buildTemplates.removeAtIndex(idx)
                break
            }
        }
        
        //also delete the file
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        let id = buildTemplate.uniqueId
        let templateUrl = templatesFolderUrl.URLByAppendingPathComponent("\(id).json")
        NSFileManager.defaultManager().removeItemAtURL(templateUrl, error: nil)
        
        //save
        self.saveBuildTemplates()
    }
    
    func removeProject(project: LocalSource) {
        
        for (idx, p) in enumerate(self.projects) {
            if project.url == p.url {
                self.projects.removeAtIndex(idx)
                return
            }
        }
    }
    
    func removeServer(serverConfig: XcodeServerConfig) {
        
        for (idx, p) in enumerate(self.servers) {
            if serverConfig.host == p.host {
                self.servers.removeAtIndex(idx)
                return
            }
        }
    }
    
    func removeSyncer(syncer: HDGitHubXCBotSyncer) {
        
        //don't know how to compare syncers yet
        self.syncers.removeAll(keepCapacity: true)
    }
    
    func loadAllFromPersistence() {
        
        self.loadProjects()
        self.loadServers()
        self.loadSyncers()
        self.loadBuildTemplates()
    }
    
    func loadServers() {
        
        self.servers.removeAll(keepCapacity: true)
        
        let serversUrl = Persistence.getFileInAppSupportWithName("ServerConfigs.json", isDirectory: false)
        let (json: AnyObject?, error) = Persistence.loadJSONFromUrl(serversUrl)
        
        if let json = json as? [NSDictionary] {
            let allConfigs = json.map { XcodeServerConfig(json: $0) }
            let parsedConfigs = allConfigs.filter { $0 != nil }.map { $0! }
            if allConfigs.count != parsedConfigs.count {
                Log.error("Some configs failed to parse, will be ignored.")
                //maybe show a popup
            }
            parsedConfigs.map { self.servers.append($0) }
            return
        }
        
        //file not found
        if error?.code != 260 {
            Log.error("Failed to read ServerConfigs, error \(error). Will be ignored. Please don't play with the persistence :(")
        }
    }
    
    func loadProjects() {
        
        self.projects.removeAll(keepCapacity: true)
        
        let projectsUrl = Persistence.getFileInAppSupportWithName("Projects.json", isDirectory: false)
        let (json: AnyObject?, error) = Persistence.loadJSONFromUrl(projectsUrl)
        
        if let json = json as? [NSDictionary] {
            let allProjects = json.map { LocalSource(json: $0) }
            let parsedProjects = allProjects.filter { $0 != nil }.map { $0! }
            if allProjects.count != parsedProjects.count {
                Log.error("Some projects failed to parse, will be ignored.")
                //maybe show a popup
            }
            parsedProjects.map { self.projects.append($0) }
            return
        }
        //file not found
        if error?.code != 260 {
            Log.error("Failed to read Projects, error \(error). Will be ignored. Please don't play with the persistence :(")
        }
    }
    
    func loadSyncers() {
        
        self.syncers.removeAll(keepCapacity: true)
        
        let syncersUrl = Persistence.getFileInAppSupportWithName("Syncers.json", isDirectory: false)
        let (json: AnyObject?, error) = Persistence.loadJSONFromUrl(syncersUrl)
        
        if let json = json as? [NSDictionary] {
            let allSyncers = json.map { HDGitHubXCBotSyncer(json: $0, storageManager: self) }
            let parsedSyncers = allSyncers.filter { $0 != nil }.map { $0! }
            if allSyncers.count != parsedSyncers.count {
                Log.error("Some syncers failed to parse, will be ignored.")
                //maybe show a popup
            }
            parsedSyncers.map { self.syncers.append($0) }
            return
        }
        //file not found
        if error?.code != 260 {
            Log.error("Failed to read Syncers, error \(error). Will be ignored. Please don't play with the persistence :(")
        }
    }
    
    func loadBuildTemplates() {
        
        self.buildTemplates.removeAll(keepCapacity: true)
        
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        Persistence.iterateThroughFilesInFolder(templatesFolderUrl, visit: { (url) -> () in
            
            let (json: AnyObject?, error) = Persistence.loadJSONFromUrl(url)
            if let json = json as? NSDictionary {
                if let template = BuildTemplate(json: json) {
                    //we have a template
                    self.buildTemplates.append(template)
                    return
                }
            }
            Log.error("Couldn't parse Build Template at url \(url), error \(error)")
        })
    }
    
    func saveProjects() {
        
        let projectsUrl = Persistence.getFileInAppSupportWithName("Projects.json", isDirectory: false)
        let jsons = self.projects.map { $0.jsonify() }
        let (success, error) = Persistence.saveJSONToUrl(jsons, url: projectsUrl)
        assert(success, "Failed to save Projects, \(error)")
    }
    
    func saveServers() {
        
        let serversUrl = Persistence.getFileInAppSupportWithName("ServerConfigs.json", isDirectory: false)
        let jsons = self.servers.map { $0.jsonify() }
        let (success, error) = Persistence.saveJSONToUrl(jsons, url: serversUrl)
        assert(success, "Failed to save ServerConfigs, \(error)")
    }
    
    func saveSyncers() {

        let syncersUrl = Persistence.getFileInAppSupportWithName("Syncers.json", isDirectory: false)
        let jsons = self.syncers.map { $0.jsonify() }
        let (success, error) = Persistence.saveJSONToUrl(jsons, url: syncersUrl)
        assert(success, "Failed to save Syncers, \(error)")
    }
    
    func saveBuildTemplates() {
        
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        self.buildTemplates.map {
            (template: BuildTemplate) -> () in
            
            let json = template.jsonify()
            let id = template.uniqueId
            let templateUrl = templatesFolderUrl.URLByAppendingPathComponent("\(id).json")
            let (success, error) = Persistence.saveJSONToUrl(json, url: templateUrl)
            assert(success, "Failed to save a Build Template, \(error)")
        }
    }
    
    func stop() {
        self.saveAll()
        self.stopSyncers()
    }
    
    func saveAll() {
        //save to persistence
        
        self.saveProjects()
        self.saveServers()
        self.saveBuildTemplates()
        self.saveSyncers()
    }
    
    private func stopSyncers() {
        
        for syncer in self.syncers {
            syncer.active = false
        }
    }
    
    private func startSyncers() {
        //start all syncers in memory
        
        for syncer in self.syncers {
            syncer.active = true
        }
    }
    
}
