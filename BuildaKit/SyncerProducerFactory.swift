//
//  SyncerManagerProducers.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import XcodeServerSDK

class SyncerProducerFactory {
    
    static func createTripletsProducer(st: StorageManager) -> SignalProducer<[ConfigTriplet], NoError> {
        
        let projectConfigs = st.projectConfigs.producer
        let serverConfigs = st.serverConfigs.producer
        let syncerConfigs = st.syncerConfigs.producer
        let buildTemplates = st.buildTemplates.producer
        let triggerConfigs = st.triggerConfigs.producer
        
        let configs = combineLatest(
            syncerConfigs,
            serverConfigs,
            projectConfigs,
            buildTemplates,
            triggerConfigs
        )
        
        typealias OptionalTuple = (SyncerConfig, XcodeServerConfig?, ProjectConfig?, BuildTemplate?, [TriggerConfig]?)
        typealias OptionalTuples = [OptionalTuple]

        //create the new set of syncers from the available data
        let latestTuples = configs.map { syncers, servers, projects, buildTemplates, triggers in
            Array(syncers.values).map { (syncerConfig: SyncerConfig) -> OptionalTuple in
                let bt = buildTemplates[syncerConfig.preferredTemplateRef]
                let triggerIds = Set(bt?.triggers ?? [])
                let ourTriggers = triggers.filter { triggerIds.contains($0.0) }.map { $0.1 }
                return (
                    syncerConfig,
                    servers[syncerConfig.xcodeServerRef],
                    projects[syncerConfig.projectRef],
                    bt,
                    ourTriggers
                )
            }
        }
        
        let nonNilTuples = latestTuples.map { (tuples: OptionalTuples) -> OptionalTuples in
            tuples.filter { (tuple: OptionalTuple) -> Bool in
                tuple.1 != nil && tuple.2 != nil && tuple.3 != nil && tuple.4 != nil
            }
        }
        let unwrapped = nonNilTuples
            .map { tuples in tuples.map { ($0.0, $0.1!, $0.2!, $0.3!, $0.4!) } }
        
        let triplets = unwrapped.map { tuples in
            return tuples.map {
                return ConfigTriplet(
                    syncer: $0.0,
                    server: $0.1,
                    project: $0.2,
                    buildTemplate: $0.3,
                    triggers: $0.4)
            }
        }
        return triplets
    }
    
    static func createSyncersProducer(factory: SyncerFactoryType, triplets: SignalProducer<[ConfigTriplet], NoError>) -> SignalProducer<[StandardSyncer], NoError> {
        
        let syncers = triplets.map { (tripletArray: [ConfigTriplet]) -> [StandardSyncer] in
            return factory.createSyncers(tripletArray)
        }
        return syncers
    }
    
    static func createProjectsProducer(factory: SyncerFactoryType, configs: SignalProducer<[ProjectConfig], NoError>) -> SignalProducer<[Project], NoError> {
        
        let projects = configs.map { configsArray in
            return configsArray.map { factory.createProject($0) }
        }.map { $0.filter { $0 != nil } }.map { $0.map { $0! } }
        return projects
    }
    
    static func createServersProducer(factory: SyncerFactoryType, configs: SignalProducer<[XcodeServerConfig], NoError>) -> SignalProducer<[XcodeServer], NoError> {
        
        let servers = configs.map { configsArray in
            return configsArray.map { factory.createXcodeServer($0) }
        }
        return servers
    }
    
    static func createBuildTemplateProducer(_: SyncerFactoryType, templates: SignalProducer<[BuildTemplate], NoError>) -> SignalProducer<[BuildTemplate], NoError> {
        //no transformation
        return templates
    }
    
    static func createTriggersProducer(factory: SyncerFactoryType, configs: SignalProducer<[TriggerConfig], NoError>) -> SignalProducer<[Trigger], NoError> {
        
        let triggers = configs.map { configsArray in
            return configsArray.map { factory.createTrigger($0) }
        }
        return triggers
    }

}
