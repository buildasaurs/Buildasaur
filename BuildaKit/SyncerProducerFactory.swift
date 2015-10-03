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
        
        let configs = combineLatest(syncerConfigs, serverConfigs, projectConfigs)
        //create the new set of syncers from the available data
        let latestTuples = configs.map { syncers, servers, projects in
            syncers.map { ($0, servers[$0.xcodeServerRef], projects[$0.projectRef]) }
        }
        let nonNilTuples = latestTuples.map { tuples in
            tuples.filter { $0.1 != nil && $0.2 != nil }
            }.map { tuples in tuples.map { ($0.0, $0.1!, $0.2!) } }
        
        let triplets = nonNilTuples.map { tuples in
            return tuples.map {
                return ConfigTriplet(syncer: $0.0, server: $0.1, project: $0.2)
            }
        }
        return triplets
    }
    
    static func createSyncersProducer(factory: SyncerFactoryType, triplets: SignalProducer<[ConfigTriplet], NoError>) -> SignalProducer<[HDGitHubXCBotSyncer], NoError> {
        
        let syncers = triplets.map { tripletArray in
            return tripletArray.map { factory.createSyncer(
                $0.syncer, serverConfig: $0.server, projectConfig: $0.project)
            }
        }
        return syncers
    }
}
