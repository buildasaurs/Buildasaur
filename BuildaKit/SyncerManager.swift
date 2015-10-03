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

//owns running syncers and their children, manages starting/stopping them,
//creating them from configurations

typealias ConfigTriplet = (SyncerConfig, XcodeServerConfig, ProjectConfig)

public class SyncerManager {
    
    public let storageManager: StorageManager
    
    public let syncersProducer: SignalProducer<[HDGitHubXCBotSyncer], NoError>
    
    private var syncers: [HDGitHubXCBotSyncer]
    private var configTriplets: SignalProducer<[ConfigTriplet], NoError>
    
    public init(storageManager: StorageManager) {
        self.storageManager = storageManager
        self.syncers = []
        let configTriplets = SyncerProducerFactory.createTripletsProducer(storageManager)
        self.configTriplets = configTriplets
        let syncersProducer = SyncerProducerFactory.createSyncersProducer(configTriplets)
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
