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
    
    public let github: MutableProperty<GitHubServer?>
    public let xcodeServer: MutableProperty<XcodeServer?>
    public let project: MutableProperty<Project?>
    
    public let config: SyncerConfig
    
    public init(integrationServer: XcodeServer, sourceServer: GitHubServer, project: Project, config: SyncerConfig) {
            
        self.github = MutableProperty(sourceServer)
        self.xcodeServer = MutableProperty(integrationServer)
        self.project = MutableProperty(project)
        
        self.config = config
        
        super.init(syncInterval: config.syncInterval)
    }
}

