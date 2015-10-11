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
    func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig, buildTemplate: BuildTemplate, triggerConfigs: [TriggerConfig]) -> HDGitHubXCBotSyncer
    func defaultConfigTriplet() -> ConfigTriplet
    func newEditableTriplet() -> EditableConfigTriplet
    func createXcodeServer(config: XcodeServerConfig) -> XcodeServer
    func createProject(config: ProjectConfig) -> Project
    func createSourceServer(token: String) -> GitHubServer
    func createTrigger(config: TriggerConfig) -> Trigger
}

public class SyncerFactory: SyncerFactoryType {
    
    private var syncerPool = [RefType: HDGitHubXCBotSyncer]()
    private var projectPool = [RefType: Project]()
    private var xcodeServerPool = [RefType: XcodeServer]()
    
    public init() { }
    
    public func createSyncer(syncerConfig: SyncerConfig, serverConfig: XcodeServerConfig, projectConfig: ProjectConfig, buildTemplate: BuildTemplate, triggerConfigs: [TriggerConfig]) -> HDGitHubXCBotSyncer {

        let xcodeServer = self.createXcodeServer(serverConfig)
        let githubServer = self.createSourceServer(projectConfig.githubToken)
        let project = self.createProject(projectConfig)
        let triggers = triggerConfigs.map { self.createTrigger($0) }

        if let poolAttempt = self.syncerPool[syncerConfig.id] {
            poolAttempt.config.value = syncerConfig
            poolAttempt.xcodeServer.config = serverConfig
            poolAttempt.project.config.value = projectConfig
            poolAttempt.buildTemplate = buildTemplate
            poolAttempt.triggers = triggers
            return poolAttempt
        }
        
        let syncer = HDGitHubXCBotSyncer(
            integrationServer: xcodeServer,
            sourceServer: githubServer,
            project: project,
            buildTemplate: buildTemplate,
            triggers: triggers,
            config: syncerConfig)
        
        self.syncerPool[syncerConfig.id] = syncer
        
        //TADAAA
        return syncer
    }
    
    public func defaultConfigTriplet() -> ConfigTriplet {
        return ConfigTriplet(syncer: SyncerConfig(), server: XcodeServerConfig(), project: ProjectConfig(), buildTemplate: BuildTemplate(), triggers: [])
    }
    
    public func newEditableTriplet() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: SyncerConfig(), server: nil, project: nil, buildTemplate: nil, triggers: nil)
    }
    
    //sort of private
    public func createXcodeServer(config: XcodeServerConfig) -> XcodeServer {
        
        if let poolAttempt = self.xcodeServerPool[config.id] {
            poolAttempt.config = config
            return poolAttempt
        }

        let server = XcodeServerFactory.server(config)
        self.xcodeServerPool[config.id] = server
        
        return server
    }
    
    public func createProject(config: ProjectConfig) -> Project {
        
        if let poolAttempt = self.projectPool[config.id] {
            poolAttempt.config.value = config
            return poolAttempt
        }
        
        //TODO: maybe this producer SHOULD throw errors, when parsing fails?
        let project = try! Project(config: config)
        self.projectPool[config.id] = project
        
        return project
    }
    
    public func createSourceServer(token: String) -> GitHubServer {
        let server = GitHubFactory.server(token)
        return server
    }
    
    public func createTrigger(config: TriggerConfig) -> Trigger {
        let trigger = Trigger(config: config)
        return trigger
    }
}
