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
        
        let configs = combineLatest(syncerConfigs, serverConfigs, projectConfigs, buildTemplates)
        
        //create the new set of syncers from the available data
        let latestTuples = configs.map { syncers, servers, projects, buildTemplates in
            syncers.map { (
                $0,
                servers[$0.xcodeServerRef],
                projects[$0.projectRef],
                buildTemplates[$0.preferredTemplateRef]) }
        }
        let nonNilTuples = latestTuples.map { tuples in
            tuples.filter { $0.1 != nil && $0.2 != nil }
            }.map { tuples in tuples.map { ($0.0, $0.1!, $0.2!, $0.3!) } }
        
        let triplets = nonNilTuples.map { tuples in
            return tuples.map {
                return ConfigTriplet(syncer: $0.0, server: $0.1, project: $0.2, buildTemplate: $0.3)
            }
        }
        return triplets
    }
    
    static func createSyncersProducer(factory: SyncerFactoryType, triplets: SignalProducer<[ConfigTriplet], NoError>) -> SignalProducer<[HDGitHubXCBotSyncer], NoError> {
        
        let syncers = triplets.map { tripletArray in
            return tripletArray.map { factory.createSyncer(
                $0.syncer, serverConfig: $0.server, projectConfig: $0.project, buildTemplate: $0.buildTemplate)
            }
        }
        return syncers
    }
    
    static func createProjectsProducer(factory: SyncerFactoryType, configs: SignalProducer<[ProjectConfig], NoError>) -> SignalProducer<[Project], NoError> {
        
        let projects = configs.map { configsArray in
            return configsArray.map { factory.createProject($0) }
        }
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
