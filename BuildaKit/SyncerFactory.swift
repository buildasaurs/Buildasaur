//
//  SyncerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer

protocol SyncerFactoryType {
    func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig) -> HDGitHubXCBotSyncer
}

class SyncerFactory: SyncerFactoryType {
    
    init() { }
    
    func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig) -> HDGitHubXCBotSyncer {
        
        let xcodeServer = self.createXcodeServer(serverConfig)
        let githubServer = self.createSourceServer(projectConfig.githubToken)
        let project = self.createProject(projectConfig)
        
        let syncer = HDGitHubXCBotSyncer(
            integrationServer: xcodeServer,
            sourceServer: githubServer,
            project: project,
            config: syncerConfig)
        
        //TADAAA
        return syncer
    }
    
    func createXcodeServer(config: XcodeServerConfig) -> XcodeServer {
        let server = XcodeServerFactory.server(config)
        return server
    }
    
    func createProject(config: ProjectConfig) -> Project {
        //TODO: maybe this producer SHOULD throw errors, when parsing fails?
        let project = try! Project(config: config)
        return project
    }
    
    func createSourceServer(token: String) -> GitHubServer {
        let server = GitHubFactory.server(token)
        return server
    }
}
