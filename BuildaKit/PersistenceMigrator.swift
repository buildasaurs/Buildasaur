//
//  PersistenceMigrator.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/12/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK
import BuildaGitServer

public protocol MigratorType {
    init(persistence: Persistence)
    var persistence: Persistence { get set }
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
        get {
            preconditionFailure("No persistence here")
        }
        set {
            for var i in self.childMigrators {
                i.persistence = newValue
            }
        }
    }
    
    internal let childMigrators: [MigratorType]
    public required init(persistence: Persistence) {
        self.childMigrators = [
            Migrator_v0_v1(persistence: persistence),
            Migrator_v1_v2(persistence: persistence),
            Migrator_v2_v3(persistence: persistence)
        ]
    }
    
    public func isMigrationRequired() -> Bool {
        return self.childMigrators.filter { $0.isMigrationRequired() }.count > 0
    }
    
    public func attemptMigration() throws {
        try self.childMigrators
            .filter { $0.isMigrationRequired() }
            .forEach { try $0.attemptMigration() }
    }
}

let kPersistenceVersion = "persistence_version"

/*
    - Config.json: persistence_version: null -> 1
*/
class Migrator_v0_v1: MigratorType {
    
    internal var persistence: Persistence
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
    
    internal var persistence: Persistence
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
        self.migrateBuildTemplates()
        self.migrateConfigAndLog()
    }
    
    func fixPath(path: String) -> String {
        let oldUrl = NSURL(string: path)
        let newPath = oldUrl!.path!
        return newPath
    }
    
    func migrateBuildTemplates() {
        
        //first pull all triggers from all build templates and save them
        //as separate files, keeping the ids around.
        
        let templates = self.persistence.loadArrayOfDictionariesFromFolder("BuildTemplates") ?? []
        guard templates.count > 0 else { return }
        let mutableTemplates = templates.map { $0.mutableCopy() as! NSMutableDictionary }
        
        //go through templates and replace full triggers with just ids
        var triggers = [NSDictionary]()
        for template in mutableTemplates {
            
            guard let tempTriggers = template["triggers"] as? [NSDictionary] else { continue }
            let mutableTempTriggers = tempTriggers.map { $0.mutableCopy() as! NSMutableDictionary }
            
            //go through each trigger and each one an id
            let trigWithIds = mutableTempTriggers.map { trigger -> NSDictionary in
                trigger["id"] = Ref.new()
                return trigger.copy() as! NSDictionary
            }
            
            //add them to the big list of triggers that we'll save later
            triggers.appendContentsOf(trigWithIds)
            
            //now gather those ids
            let triggerIds = trigWithIds.map { $0.stringForKey("id") }
            
            //and replace the "triggers" array in the build template with these ids
            template["triggers"] = triggerIds
        }
        
        //now save all triggers into their own folder
        self.persistence.saveArrayIntoFolder("Triggers", items: triggers, itemFileName: { $0.stringForKey("id") }, serialize: { $0 })

        //and save the build templates
        self.persistence.saveArrayIntoFolder("BuildTemplates", items: mutableTemplates, itemFileName: { $0.stringForKey("id") }, serialize: { $0 })
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
        
        //fix internal urls to be normal paths instead of the file:/// paths
        let withFixedUrls = withIds.map { project -> NSMutableDictionary in
            project["url"] = self.fixPath(project.stringForKey("url"))
            project["ssh_public_key_url"] = self.fixPath(project.stringForKey("ssh_public_key_url"))
            project["ssh_private_key_url"] = self.fixPath(project.stringForKey("ssh_private_key_url"))
            return project
        }
        
        //remove preferred_template_id, will be moved to syncer
        let removedTemplate = withFixedUrls.map { project -> (RefType?, NSMutableDictionary) in
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

/*
- ServerConfigs.json: password moved to the keychain
- Projects.json: github_token -> oauth_tokens keychain, ssh_passphrase moved to keychain
- move any .log files to a separate folder called 'Logs'
- "token1234" -> "github:username:personaltoken:token1234"
*/
class Migrator_v2_v3: MigratorType {
    
    internal var persistence: Persistence
    required init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func isMigrationRequired() -> Bool {
        
        return self.persistenceVersion() == 2
    }
    
    func attemptMigration() throws {
        
        let pers = self.persistence
        
        //migrate
        self.migrateProjectAuthentication()
        self.migrateServerAuthentication()
        self.migrateLogs()
        
        //copy the rest
        pers.copyFileToWriteLocation("Syncers.json", isDirectory: false)
        pers.copyFileToWriteLocation("BuildTemplates", isDirectory: true)
        pers.copyFileToWriteLocation("Triggers", isDirectory: true)
        
        let config = self.config()
        let mutableConfig = config.mutableCopy() as! NSMutableDictionary
        mutableConfig[kPersistenceVersion] = 3
        
        //save the updated config
        pers.saveDictionary("Config.json", item: mutableConfig)
    }

    func migrateProjectAuthentication() {
        
        let pers = self.persistence
        let projects = pers.loadArrayOfDictionariesFromFile("Projects.json") ?? []
        let mutableProjects = projects.map { $0.mutableCopy() as! NSMutableDictionary }

        let renamedAuth = mutableProjects.map {
            (d: NSMutableDictionary) -> NSDictionary in
            
            let id = d.stringForKey("id")
            let token = d.stringForKey("github_token")
            let auth = ProjectAuthenticator(service: .GitHub, username: "GIT", type: .PersonalToken, secret: token)
            let formattedToken = auth.toString()

            let passphrase = d.optionalStringForKey("ssh_passphrase")
            d.removeObjectForKey("github_token")
            d.removeObjectForKey("ssh_passphrase")
            
            let tokenKeychain = SecurePersistence.sourceServerTokenKeychain()
            tokenKeychain.writeIfNeeded(id, value: formattedToken)
            
            let passphraseKeychain = SecurePersistence.sourceServerPassphraseKeychain()
            passphraseKeychain.writeIfNeeded(id, value: passphrase)
            
            precondition(tokenKeychain.read(id) == formattedToken, "Saved token must match")
            precondition(passphraseKeychain.read(id) == passphrase, "Saved passphrase must match")
            
            return d
        }
        
        pers.saveArray("Projects.json", items: renamedAuth)
    }
    
    func migrateServerAuthentication() {

        let pers = self.persistence
        let servers = pers.loadArrayOfDictionariesFromFile("ServerConfigs.json") ?? []
        let mutableServers = servers.map { $0.mutableCopy() as! NSMutableDictionary }
        
        let withoutPasswords = mutableServers.map {
            (d: NSMutableDictionary) -> NSDictionary in
            
            let password = d.stringForKey("password")
            let key = (try! XcodeServerConfig(json: d)).keychainKey()
            
            let keychain = SecurePersistence.xcodeServerPasswordKeychain()
            keychain.writeIfNeeded(key, value: password)
            
            d.removeObjectForKey("password")
            
            precondition(keychain.read(key) == password, "Saved password must match")
            
            return d
        }
        
        pers.saveArray("ServerConfigs.json", items: withoutPasswords)
    }
    
    func migrateLogs() {
        
        let pers = self.persistence
        (pers.filesInFolder(pers.folderForIntention(.Reading)) ?? [])
            .map { $0.lastPathComponent ?? "" }
            .filter { $0.hasSuffix("log") }
            .forEach {
                pers.copyFileToFolder($0, folder: "Logs")
                pers.deleteFile($0)
        }
    }
}

