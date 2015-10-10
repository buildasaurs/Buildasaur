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
        
        self.projectsProducer = SyncerProducerFactory.createProjectsProducer(factory, configs: justProjects)
        self.serversProducer = SyncerProducerFactory.createServersProducer(factory, configs: justServers)
        self.buildTemplatesProducer = SyncerProducerFactory.createBuildTemplateProducer(factory, templates: justBuildTemplates)
        self.triggerProducer = SyncerProducerFactory.createTriggersProducer(factory, configs: justTriggerConfigs)
        
        syncersProducer.startWithNext { [weak self] in self?.syncers = $0 }
    }
    
    public func xcodeServerWithRef(ref: RefType) -> SignalProducer<XcodeServer?, NoError> {
        
        return self.serversProducer.map { allServers -> XcodeServer? in
            return allServers.filter { $0.config.id == ref }.first
        }
    }
    
    public func projectWithRef(ref: RefType) -> SignalProducer<Project?, NoError> {
        
        return self.projectsProducer.map { allProjects -> Project? in
            return allProjects.filter { $0.config.value.id == ref }.first
        }
    }
    
    public func syncerWithRef(ref: RefType) -> SignalProducer<HDGitHubXCBotSyncer?, NoError> {
        
        return self.syncersProducer.map { allSyncers -> HDGitHubXCBotSyncer? in
            return allSyncers.filter { $0.config.value.id == ref }.first
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
