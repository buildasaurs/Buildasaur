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

public class StorageManager {
    
    public static let sharedInstance = StorageManager()
    
    private(set) public var syncers: [HDGitHubXCBotSyncer] = []
    private(set) public var servers: [XcodeServerConfig] = []
    private(set) public var projects: [Project] = []
    private(set) public var buildTemplates: [BuildTemplate] = []
    
    init() {
        
        //initialize all stored Syncers
        self.loadAllFromPersistence()
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
        self.syncers.removeAll(keepCapacity: true)
    }
    
    public func loadAllFromPersistence() {
        
        self.loadProjects()
        self.loadServers()
        self.loadSyncers()
        self.loadBuildTemplates()
    }
    
    func loadServers() {
        
        self.servers.removeAll(keepCapacity: true)
        
        let serversUrl = Persistence.getFileInAppSupportWithName("ServerConfigs.json", isDirectory: false)
        do {
            let json = try Persistence.loadJSONFromUrl(serversUrl)
            
            if let json = json as? [NSDictionary] {
                let allConfigs = json.map { (item) -> XcodeServerConfig? in
                    do { return try XcodeServerConfig(json: item) } catch { return nil }
                }
                let parsedConfigs = allConfigs.filter { $0 != nil }.map { $0! }
                if allConfigs.count != parsedConfigs.count {
                    Log.error("Some configs failed to parse, will be ignored.")
                    //maybe show a popup
                }
                parsedConfigs.map { self.servers.append($0) }
                return
            }
        } catch {
            //file not found
            if (error as NSError).code != 260 {
                Log.error("Failed to read ServerConfigs, error \(error). Will be ignored. Please don't play with the persistence :(")
            }
        }
    }
    
    func loadProjects() {
        
        self.projects.removeAll(keepCapacity: true)
        
        let projectsUrl = Persistence.getFileInAppSupportWithName("Projects.json", isDirectory: false)
        do {
            let json = try Persistence.loadJSONFromUrl(projectsUrl)
            
            if let json = json as? [NSDictionary] {
                let allProjects = json.map { Project(json: $0) }
                let parsedProjects = allProjects.filter { $0 != nil }.map { $0! }
                if allProjects.count != parsedProjects.count {
                    Log.error("Some projects failed to parse, will be ignored.")
                    //maybe show a popup
                }
                parsedProjects.map { self.projects.append($0) }
                return
            }
        } catch {
            //file not found
            if (error as NSError).code != 260 {
                Log.error("Failed to read Projects, error \(error). Will be ignored. Please don't play with the persistence :(")
            }
        }
    }
    
    func loadSyncers() {
        
        self.syncers.removeAll(keepCapacity: true)
        
        let syncersUrl = Persistence.getFileInAppSupportWithName("Syncers.json", isDirectory: false)
        do {
            let json = try Persistence.loadJSONFromUrl(syncersUrl)
            
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
        } catch {
            //file not found
            if (error as NSError).code != 260 {
                Log.error("Failed to read Syncers, error \(error). Will be ignored. Please don't play with the persistence :(")
            }
        }
    }
    
    func loadBuildTemplates() {
        
        self.buildTemplates.removeAll(keepCapacity: true)
        
        let templatesFolderUrl = Persistence.getFileInAppSupportWithName("BuildTemplates", isDirectory: true)
        Persistence.iterateThroughFilesInFolder(templatesFolderUrl, visit: { (url) -> () in
            
            do {
                let json = try Persistence.loadJSONFromUrl(url)
                if let json = json as? NSDictionary {
                    if let template = BuildTemplate(json: json) {
                        //we have a template
                        self.buildTemplates.append(template)
                        return
                    }
                }
            } catch {
                Log.error("Couldn't parse Build Template at url \(url), error \(error)")
            }
        })
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
        self.buildTemplates.map {
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
