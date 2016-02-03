//
//  StandardSyncer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import XcodeServerSDK
import ReactiveCocoa

public class StandardSyncer : Syncer {
    
    public var sourceServer: SourceServerType
    public var xcodeServer: XcodeServer
    public var project: Project
    public var buildTemplate: BuildTemplate
    public var triggers: [Trigger]
    
    public let config: MutableProperty<SyncerConfig>
    
    public var configTriplet: ConfigTriplet {
        return ConfigTriplet(syncer: self.config.value, server: self.xcodeServer.config, project: self.project.config.value, buildTemplate: self.buildTemplate, triggers: self.triggers.map { $0.config })
    }
    
    public init(integrationServer: XcodeServer, sourceServer: SourceServerType, project: Project, buildTemplate: BuildTemplate, triggers: [Trigger], config: SyncerConfig) {

        self.config = MutableProperty<SyncerConfig>(config)

        self.sourceServer = sourceServer
        self.xcodeServer = integrationServer
        self.project = project
        self.buildTemplate = buildTemplate
        self.triggers = triggers
        
        super.init(syncInterval: config.syncInterval)
        
        self.config.producer.startWithNext { [weak self] in
            self?.syncInterval = $0.syncInterval
        }
    }
    
    deinit {
        self.active = false
    }
    
    public override func sync(completion: () -> ()) {
        
        if let repoName = self.repoName() {
            
            self.syncRepoWithName(repoName, completion: completion)
        } else {
            self.notifyErrorString("Nil repo name", context: "Syncing")
            completion()
        }
    }
}

