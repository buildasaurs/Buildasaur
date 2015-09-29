//
//  SyncerViewModel.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 28/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit
import ReactiveCocoa

struct SyncerViewModel {
    
    let syncer: HDGitHubXCBotSyncer
    
    let status: SignalProducer<String, NoError>
    let host: SignalProducer<String, NoError>
    let projectName: SignalProducer<String, NoError>
    let buildTemplateName: SignalProducer<String, NoError>
    let editButtonTitle: SignalProducer<String, NoError>
    let editButtonEnabled: SignalProducer<Bool, NoError>
    let controlButtonTitle: SignalProducer<String, NoError>
    
    init(syncer: HDGitHubXCBotSyncer) {
        self.syncer = syncer
        
        let active = syncer.activeSignalProducer.producer
        
        self.status = active.map { SyncerViewModel.stringForState($0) }
        
        self.host = SignalProducer(value: syncer.xcodeServer.config.host)
            .map { NSURL(string: $0)!.host! }
        
        self.projectName = SignalProducer(value: syncer.project.workspaceMetadata!.projectName)
        self.buildTemplateName = SignalProducer(value: syncer.currentBuildTemplate().name!)
        self.editButtonTitle = SignalProducer(value: "Edit")
        self.editButtonEnabled = active.map { !$0 }
        self.controlButtonTitle = active.map { $0 ? "Stop" : "Start" }
    }
    
    func editButtonClicked() {
        
    }
    
    func startButtonClicked() {
        //TODO: run through validation first?
        self.syncer.active = true
    }
    
    func stopButtonClicked() {
        self.syncer.active = false
    }
    
    func controlButtonClicked() {
        //TODO: run through validation first?
        self.syncer.active = !self.syncer.active
    }
    
    private static func stringForState(active: Bool) -> String {
        if active {
            return "✔️ syncing..."
        } else {
            return "✖️ stopped."
        }
    }
    
}

