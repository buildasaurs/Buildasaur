//
//  PersistenceMigrator.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/12/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public protocol MigratorType {
    init(persistence: Persistence)
    var persistence: Persistence { get }
    func isMigrationRequired() -> Bool
    func attemptMigration() throws
}

extension MigratorType {
    
    func config() -> NSDictionary {
        let config = self.persistence.loadDictionaryFromFile("Config.json") ?? [:]
        return config
    }
    
    func persistenceVersion() -> Int? {
        let config = self.config()
        let version = config.optionalIntForKey(kPersistenceVersion)
        return version
    }
}

public class CompositeMigrator: MigratorType {
    
    public var persistence: Persistence {
        preconditionFailure("No persistence here")
    }
    
    private let childMigrators: [MigratorType]
    public required init(persistence: Persistence) {
        self.childMigrators = [
            Migrator_v0_v1(persistence: persistence),
            Migrator_v1_v2(persistence: persistence)
        ]
    }
    
    public func isMigrationRequired() -> Bool {
        return self.childMigrators.filter { $0.isMigrationRequired() }.count > 0
    }
    
    public func attemptMigration() throws {
        try self.childMigrators.forEach { try $0.attemptMigration() }
    }
}

let kPersistenceVersion = "persistence_version"

/*
    - Config.json: persistence_version: null -> 1
*/
class Migrator_v0_v1: MigratorType {
    
    internal let persistence: Persistence
    required init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func isMigrationRequired() -> Bool {
        
        //we need to migrate if there's no persistence version, assume 1
        let version = self.persistenceVersion()
        return (version == nil)
    }
    
    func attemptMigration() throws {
        
        let pers = self.persistence
        //make sure the config file has a persistence version number
        let version = self.persistenceVersion()
        guard version == nil else {
            //all good
            return
        }
        
        let config = self.config()
        let mutableConfig = config.mutableCopy() as! NSMutableDictionary
        mutableConfig[kPersistenceVersion] = 1
        
        //save the updated config
        pers.saveDictionary("Config.json", item: mutableConfig)
        
        //copy the rest
        pers.copyFileToWriteLocation("Builda.log", isDirectory: false)
        pers.copyFileToWriteLocation("Projects.json", isDirectory: false)
        pers.copyFileToWriteLocation("ServerConfigs.json", isDirectory: false)
        pers.copyFileToWriteLocation("Syncers.json", isDirectory: false)
        pers.copyFileToWriteLocation("BuildTemplates", isDirectory: true)
    }
}

/*
    - ServerConfigs.json: each server now has an id


    - Config.json: persistence_version: 1 -> 2
*/
class Migrator_v1_v2: MigratorType {
    
    internal let persistence: Persistence
    required init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func isMigrationRequired() -> Bool {
        
        return self.persistenceVersion() == 1
    }
    
    func attemptMigration() throws {
        
        let serverRef = self.migrateServers()
        let (templateRef, projectRef) = self.migrateProjects()
        self.migrateSyncers(serverRef, project: projectRef, template: templateRef)
        
        self.migrateConfigAndLog()
    }
    
    func migrateBuildTemplates() {
        //TODO: (also triggers inside!)
    }
    
    func migrateSyncers(server: RefType?, project: RefType?, template: RefType?) {
        
        let syncers = self.persistence.loadArrayOfDictionariesFromFile("Syncers.json") ?? []
        let mutableSyncers = syncers.map { $0.mutableCopy() as! NSMutableDictionary }
        
        //give each an id
        let withIds = mutableSyncers.map { syncer -> NSMutableDictionary in
            syncer["id"] = Ref.new()
            return syncer
        }
        
        //remove server host and project path and add new ids
        let updated = withIds.map { syncer -> NSMutableDictionary in
            syncer.removeObjectForKey("server_host")
            syncer.removeObjectForKey("project_path")
            syncer.optionallyAddValueForKey(server, key: "server_ref")
            syncer.optionallyAddValueForKey(project, key: "project_ref")
            syncer.optionallyAddValueForKey(template, key: "preferred_template_ref")
            return syncer
        }
        
        self.persistence.saveArray("Syncers.json", items: updated)
    }
    
    func migrateProjects() -> (template: RefType?, project: RefType?) {
        
        let projects = self.persistence.loadArrayOfDictionariesFromFile("Projects.json") ?? []
        let mutableProjects = projects.map { $0.mutableCopy() as! NSMutableDictionary }
        
        //give each an id
        let withIds = mutableProjects.map { project -> NSMutableDictionary in
            project["id"] = Ref.new()
            return project
        }
        
        //remove preferred_template_id, will be moved to syncer
        let removedTemplate = withIds.map { project -> (RefType?, NSMutableDictionary) in
            let template = project["preferred_template_id"] as? RefType
            project.removeObjectForKey("preferred_template_id")
            return (template, project)
        }
        
        //get just the projects
        let finalProjects = removedTemplate.map { $0.1 }
        
        let firstTemplate = removedTemplate.map { $0.0 }.first ?? nil
        let firstProject = finalProjects.first?["id"] as? RefType
        
        //save
        self.persistence.saveArray("Projects.json", items: finalProjects)
        
        return (firstTemplate, firstProject)
    }
    
    func migrateServers() -> (RefType?) {
        
        let servers = self.persistence.loadArrayOfDictionariesFromFile("ServerConfigs.json") ?? []
        let mutableServers = servers.map { $0.mutableCopy() as! NSMutableDictionary }

        //give each an id
        let withIds = mutableServers.map { server -> NSMutableDictionary in
            server["id"] = Ref.new()
            return server
        }
        
        //save
        self.persistence.saveArray("ServerConfigs.json", items: withIds)
        
        //return the first/only one (there should be 0 or 1)
        let firstId = withIds.first?["id"] as? RefType
        return firstId
    }
    
    func migrateConfigAndLog() {
        
        //copy log
        self.persistence.copyFileToWriteLocation("Builda.log", isDirectory: false)
        
        let config = self.config()
        let mutableConfig = config.mutableCopy() as! NSMutableDictionary
        mutableConfig[kPersistenceVersion] = 2
        
        //save the updated config
        self.persistence.saveDictionary("Config.json", item: mutableConfig)
    }
}
