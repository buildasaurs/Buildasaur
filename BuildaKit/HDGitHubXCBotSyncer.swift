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

public protocol SyncerDelegate: class {
    
    func syncerBuildTemplates(syncer: HDGitHubXCBotSyncer) -> [BuildTemplate]
    func syncer(syncer: HDGitHubXCBotSyncer, triggersWithIds triggerIds: [RefType]) -> [Trigger]
}

public class HDGitHubXCBotSyncer : Syncer {
    
    weak var delegate: SyncerDelegate?
    
    public let github: GitHubServer
    public let xcodeServer: XcodeServer
    public let project: Project
    public let buildTemplate: BuildTemplate
    public let config: SyncerConfig
    
    public var configTriplet: ConfigTriplet {
        return ConfigTriplet(syncer: self.config, server: self.xcodeServer.config, project: self.project.config, buildTemplate: self.buildTemplate)
    }
    
    public init(integrationServer: XcodeServer, sourceServer: GitHubServer, project: Project, buildTemplate: BuildTemplate, config: SyncerConfig) {
            
        self.github = sourceServer
        self.xcodeServer = integrationServer
        self.project = project
        self.buildTemplate = buildTemplate
        
        self.config = config
        
        super.init(syncInterval: config.syncInterval)
    }
}

