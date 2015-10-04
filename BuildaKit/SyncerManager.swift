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
    
    public func toEditable() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: self.syncer, server: self.server, project: self.project)
    }
}

public struct EditableConfigTriplet {
    public var syncer: SyncerConfig
    public var server: XcodeServerConfig?
    public var project: ProjectConfig?
}

//owns running syncers and their children, manages starting/stopping them,
//creating them from configurations

public class SyncerManager {
    
    public let storageManager: StorageManager
    public let factory: SyncerFactoryType
    
    public let syncersProducer: SignalProducer<[HDGitHubXCBotSyncer], NoError>
    
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
        syncersProducer.startWithNext { self.syncers = $0 }
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
