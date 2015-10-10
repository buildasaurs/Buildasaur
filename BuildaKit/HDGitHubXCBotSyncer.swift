//
//  HDGitHubXCBotSyncer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import XcodeServerSDK
import ReactiveCocoa

public class HDGitHubXCBotSyncer : Syncer {
    
    public let github: GitHubServer
    public let xcodeServer: XcodeServer
    public let project: Project
    public let buildTemplate: BuildTemplate
    public let triggers: [Trigger]
    
    public let config: MutableProperty<SyncerConfig>
    
    public var configTriplet: ConfigTriplet {
        return ConfigTriplet(syncer: self.config.value, server: self.xcodeServer.config, project: self.project.config.value, buildTemplate: self.buildTemplate, triggers: self.triggers.map { $0.config })
    }
    
    public init(integrationServer: XcodeServer, sourceServer: GitHubServer, project: Project, buildTemplate: BuildTemplate, triggers: [Trigger], config: SyncerConfig) {

        self.config = MutableProperty<SyncerConfig>(config)

        self.github = sourceServer
        self.xcodeServer = integrationServer
        self.project = project
        self.buildTemplate = buildTemplate
        self.triggers = triggers
        
        super.init(syncInterval: config.syncInterval)
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

