//
//  SyncerManager.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

//owns running syncers and their children, manages starting/stopping them,
//creating them from configurations

public class SyncerManager {
    
    public func stopSyncers() {
//        self.syncerConfigs.value.forEach { $0.active = false }
    }
    
    public func startSyncers() {
//        self.syncerConfigs.value.forEach { $0.active = true }
    }
    
    public func stop() {
//        self.storageManager.saveAll()
//        self.saveAll()
        self.stopSyncers()
    }

}
