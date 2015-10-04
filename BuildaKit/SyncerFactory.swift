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

public protocol SyncerFactoryType {
    func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig) -> HDGitHubXCBotSyncer
    func defaultConfigTriplet() -> ConfigTriplet
    func newEditableTriplet() -> EditableConfigTriplet
    func createXcodeServer(config: XcodeServerConfig) -> XcodeServer
    func createProject(config: ProjectConfig) -> Project
    func createSourceServer(token: String) -> GitHubServer
}

public class SyncerFactory: SyncerFactoryType {
    
    public init() { }
    
    public func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig) -> HDGitHubXCBotSyncer {
        
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
    
    public func defaultConfigTriplet() -> ConfigTriplet {
        return ConfigTriplet(syncer: SyncerConfig(), server: XcodeServerConfig(), project: ProjectConfig())
    }
    
    public func newEditableTriplet() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: SyncerConfig(), server: nil, project: nil)
    }
    
    //sort of private
    public func createXcodeServer(config: XcodeServerConfig) -> XcodeServer {
        let server = XcodeServerFactory.server(config)
        return server
    }
    
    public func createProject(config: ProjectConfig) -> Project {
        //TODO: maybe this producer SHOULD throw errors, when parsing fails?
        let project = try! Project(config: config)
        return project
    }
    
    public func createSourceServer(token: String) -> GitHubServer {
        let server = GitHubFactory.server(token)
        return server
    }
}
