//
//  StorageManager.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK
import ReactiveCocoa
import BuildaGitServer

public enum StorageManagerError: ErrorType {
    case DuplicateServerConfig(XcodeServerConfig)
    case DuplicateProjectConfig(ProjectConfig)
}

public class StorageManager {
    
    public let syncerConfigs = MutableProperty<[String: SyncerConfig]>([:])
    public let serverConfigs = MutableProperty<[String: XcodeServerConfig]>([:])
    public let projectConfigs = MutableProperty<[String: ProjectConfig]>([:])
    public let buildTemplates = MutableProperty<[String: BuildTemplate]>([:])
    public let triggerConfigs = MutableProperty<[String: TriggerConfig]>([:])
    public let config = MutableProperty<[String: AnyObject]>([:])
    
    let tokenKeychain = SecurePersistence.sourceServerTokenKeychain()
    let passphraseKeychain = SecurePersistence.sourceServerPassphraseKeychain()
    let serverConfigKeychain = SecurePersistence.xcodeServerPasswordKeychain()
    
    private let persistence: Persistence
    
    public init(persistence: Persistence) {
        
        self.persistence = persistence
        self.loadAllFromPersistence()
        self.setupSaving()
    }
    
    deinit {
        //
    }
    
    public func checkForProjectOrWorkspace(url: NSURL) throws {
        _ = try Project.attemptToParseFromUrl(url)
    }
    
    //MARK: adding

    public func addSyncerConfig(config: SyncerConfig) {
        self.syncerConfigs.value[config.id] = config
    }

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
    
    public func removeSyncer(syncerConfig: SyncerConfig) {
        
        //TODO: make sure this syncer config is not owned by a syncer which
        //is running right now.
        self.syncerConfigs.value.removeValueForKey(syncerConfig.id)
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
        
        self.config.value = self.persistence.loadDictionaryFromFile("Config.json") ?? [:]
        
        let allProjects: [ProjectConfig] = self.persistence.loadArrayFromFile("Projects.json") ?? []
        //load server token & ssh passphrase from keychain
        let tokenKeychain = self.tokenKeychain
        let passphraseKeychain = self.passphraseKeychain
        self.projectConfigs.value = allProjects
            .map {
                (var p: ProjectConfig) -> ProjectConfig in
                var auth: ProjectAuthenticator?
                if let val = tokenKeychain.read(p.keychainKey()) {
                    auth = try? ProjectAuthenticator.fromString(val)
                }
                p.serverAuthentication = auth
                p.sshPassphrase = passphraseKeychain.read(p.keychainKey())
                return p
            }.dictionarifyWithKey { $0.id }
        
        let allServerConfigs: [XcodeServerConfig] = self.persistence.loadArrayFromFile("ServerConfigs.json") ?? []
        //load xcs passwords from keychain
        let xcsConfigKeychain = self.serverConfigKeychain
        self.serverConfigs.value = allServerConfigs
            .map {
                (var x: XcodeServerConfig) -> XcodeServerConfig in
                x.password = xcsConfigKeychain.read(x.keychainKey())
                return x
            }.dictionarifyWithKey { $0.id }
        
        let allTemplates: [BuildTemplate] = self.persistence.loadArrayFromFolder("BuildTemplates") ?? []
        self.buildTemplates.value = allTemplates.dictionarifyWithKey { $0.id }
        let allTriggers: [TriggerConfig] = self.persistence.loadArrayFromFolder("Triggers") ?? []
        self.triggerConfigs.value = allTriggers.dictionarifyWithKey { $0.id }
        let allSyncers: [SyncerConfig] = self.persistence.loadArrayFromFile("Syncers.json") { self.createSyncerConfigFromJSON($0) } ?? []
        self.syncerConfigs.value = allSyncers.dictionarifyWithKey { $0.id }
    }
    
    //MARK: Saving
    
    private func setupSaving() {
        
        //simple - save on every change after the initial bunch has been loaded!
        
        self.serverConfigs.producer.startWithNext { [weak self] in
            self?.saveServerConfigs($0)
        }
        self.projectConfigs.producer.startWithNext { [weak self] in
            self?.saveProjectConfigs($0)
        }
        self.config.producer.startWithNext { [weak self] in
            self?.saveConfig($0)
        }
        self.syncerConfigs.producer.startWithNext { [weak self] in
            self?.saveSyncerConfigs($0)
        }
        self.buildTemplates.producer.startWithNext { [weak self] in
            self?.saveBuildTemplates($0)
        }
        self.triggerConfigs.producer.startWithNext { [weak self] in
            self?.saveTriggerConfigs($0)
        }
    }
    
    private func saveConfig(config: [String: AnyObject]) {
        self.persistence.saveDictionary("Config.json", item: config)
    }
    
    private func saveProjectConfigs(configs: [String: ProjectConfig]) {
        let projectConfigs: NSArray = Array(configs.values).map { $0.jsonify() }
        let tokenKeychain = SecurePersistence.sourceServerTokenKeychain()
        let passphraseKeychain = SecurePersistence.sourceServerPassphraseKeychain()
        configs.values.forEach {
            if let auth = $0.serverAuthentication {
                tokenKeychain.writeIfNeeded($0.keychainKey(), value: auth.toString())
            }
            passphraseKeychain.writeIfNeeded($0.keychainKey(), value: $0.sshPassphrase)
        }
        self.persistence.saveArray("Projects.json", items: projectConfigs)
    }
    
    private func saveServerConfigs(configs: [String: XcodeServerConfig]) {
        let serverConfigs = Array(configs.values).map { $0.jsonify() }
        let serverConfigKeychain = SecurePersistence.xcodeServerPasswordKeychain()
        configs.values.forEach {
            serverConfigKeychain.writeIfNeeded($0.keychainKey(), value: $0.password)
        }
        self.persistence.saveArray("ServerConfigs.json", items: serverConfigs)
    }
    
    private func saveSyncerConfigs(configs: [String: SyncerConfig]) {
        let syncerConfigs = Array(configs.values).map { $0.jsonify() }
        self.persistence.saveArray("Syncers.json", items: syncerConfigs)
    }
    
    private func saveBuildTemplates(templates: [String: BuildTemplate]) {
        
        //but first we have to *delete* the directory first.
        //think of a nicer way to do this, but this at least will always
        //be consistent.
        let folderName = "BuildTemplates"
        self.persistence.deleteFolder(folderName)
        let items = Array(templates.values)
        self.persistence.saveArrayIntoFolder(folderName, items: items) { $0.id }
    }
    
    private func saveTriggerConfigs(configs: [String: TriggerConfig]) {
        
        //but first we have to *delete* the directory first.
        //think of a nicer way to do this, but this at least will always
        //be consistent.
        let folderName = "Triggers"
        self.persistence.deleteFolder(folderName)
        let items = Array(configs.values)
        self.persistence.saveArrayIntoFolder(folderName, items: items) { $0.id }
    }
}

extension StorageManager: SyncerLifetimeChangeObserver {
    
    public func authChanged(projectConfigId: String, auth: ProjectAuthenticator) {
        
        //and modify in the owner's config
        var config = self.projectConfigs.value[projectConfigId]!

        //auth info changed, re-save it into the keychain
        self.tokenKeychain.writeIfNeeded(config.keychainKey(), value: auth.toString())
        
        config.serverAuthentication = auth
        self.projectConfigs.value[projectConfigId] = config
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
