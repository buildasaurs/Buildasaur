//
//  SyncerManager.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import XcodeServerSDK

//TODO: remove invalid configs on startup?

public struct ConfigTriplet {
    public var syncer: SyncerConfig
    public var server: XcodeServerConfig
    public var project: ProjectConfig
    public var buildTemplate: BuildTemplate
    
    init(syncer: SyncerConfig, server: XcodeServerConfig, project: ProjectConfig, buildTemplate: BuildTemplate) {
        self.syncer = syncer
        self.server = server
        self.project = project
        self.buildTemplate = buildTemplate
        self.syncer.preferredTemplateRef = buildTemplate.id
    }
    
    public func toEditable() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: self.syncer, server: self.server, project: self.project, buildTemplate: self.buildTemplate)
    }
}

public struct EditableConfigTriplet {
    public var syncer: SyncerConfig
    public var server: XcodeServerConfig?
    public var project: ProjectConfig?
    public var buildTemplate: BuildTemplate?
    
    public func toFinal() -> ConfigTriplet {
        var syncer = self.syncer
        syncer.preferredTemplateRef = self.buildTemplate!.id
        return ConfigTriplet(syncer: syncer, server: self.server!, project: self.project!, buildTemplate: self.buildTemplate!)
    }
}

//owns running syncers and their children, manages starting/stopping them,
//creating them from configurations

public class SyncerManager {
    
    public let storageManager: StorageManager
    public let factory: SyncerFactoryType
    
    public let syncersProducer: SignalProducer<[HDGitHubXCBotSyncer], NoError>
    public let projectsProducer: SignalProducer<[Project], NoError>
    public let serversProducer: SignalProducer<[XcodeServer], NoError>
    
    public let buildTemplatesProducer: SignalProducer<[BuildTemplate], NoError>
    public let triggerProducer: SignalProducer<[Trigger], NoError>
    
    private var syncers: [HDGitHubXCBotSyncer]
    private var configTriplets: SignalProducer<[ConfigTriplet], NoError>
    
    public init(storageManager: StorageManager, factory: SyncerFactoryType) {
        
        self.storageManager = storageManager
        self.factory = factory
        self.syncers = []
        let configTriplets = SyncerProducerFactory.createTripletsProducer(storageManager)
        self.configTriplets = configTriplets
        let syncersProducer = SyncerProducerFactory.createSyncersProducer(factory, triplets: configTriplets)

        self.syncersProducer = syncersProducer
        
        let justProjects = storageManager.projectConfigs.producer.map { $0.map { $0.1 } }
        let justServers = storageManager.serverConfigs.producer.map { $0.map { $0.1 } }
        let justBuildTemplates = storageManager.buildTemplates.producer.map { $0.map { $0.1 } }
        let justTriggerConfigs = storageManager.triggerConfigs.producer.map { $0.map { $0.1 } }

        //TODO: shouldn't we keep the actual classes (project, xcode server) in
        //memory just once and whenever their config changes, change them live?
        //otherwise on any change of any config all syncers will need to completely reload. :(
        //! we should keep a pool of weak refs to the created objects.
        //and resend the same one when found. otherwise create.
        //should probably be an implementation detail of the library.
        
        self.projectsProducer = SyncerProducerFactory.createProjectsProducer(factory, configs: justProjects)
        self.serversProducer = SyncerProducerFactory.createServersProducer(factory, configs: justServers)
        self.buildTemplatesProducer = SyncerProducerFactory.createBuildTemplateProducer(factory, templates: justBuildTemplates)
        self.triggerProducer = SyncerProducerFactory.createTriggersProducer(factory, configs: justTriggerConfigs)
        
        syncersProducer.startWithNext { [weak self] in self?.syncers = $0 }
        
        //also attach self as delegate
        syncersProducer.startWithNext { [weak self] in $0.forEach { $0.delegate = self } }
    }
    
    public func xcodeServerWithRef(ref: RefType) -> SignalProducer<XcodeServer?, NoError> {
        
        return self.serversProducer.map { allServers -> XcodeServer? in
            return allServers.filter { $0.config.id == ref }.first
        }
    }
    
    public func projectWithRef(ref: RefType) -> SignalProducer<Project?, NoError> {
        
        return self.projectsProducer.map { allProjects -> Project? in
            return allProjects.filter { $0.config.id == ref }.first
        }
    }
    
    deinit {
        self.stopSyncers()
    }
    
    public func startSyncers() {
        self.syncers.forEach { $0.active = true }
    }

    public func stopSyncers() {
        self.syncers.forEach { $0.active = false }
    }
}

extension SyncerManager: SyncerDelegate {
    
    public func syncerBuildTemplates(syncer: HDGitHubXCBotSyncer) -> [BuildTemplate] {
        
        guard
            let result = self.buildTemplatesProducer.first(),
            case .Success(let val) = result else {
                fatalError("No errors should be sent here")
        }
        return val
    }
    
    public func syncer(syncer: HDGitHubXCBotSyncer, triggersWithIds triggerIds: [RefType]) -> [Trigger] {
        
        guard
            let result = self.triggerProducer.first(),
            case .Success(let val) = result else {
                fatalError("No errors should be sent here")
        }
        let filter = Set(triggerIds)
        let filtered = val.filter { filter.contains($0.config.id) }
        return filtered
    }
}
