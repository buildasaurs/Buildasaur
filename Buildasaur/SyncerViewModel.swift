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

struct SyncerStatePresenter {
    
    static func stringForState(state: SyncerEventType, active: Bool) -> String {
        
        guard active else {
            return "🚧 stopped"
        }
        
        let errorGen = { () -> String in
            "❗ error!"
        }
        
        switch state {
        case .DidStartSyncing:
            return "🔄 syncing..."
        case .DidFinishSyncing(let error):
            if error != nil {
                return errorGen()
            }
        case .DidEncounterError(_):
            return errorGen()
        default: break
        }
        return "✅ idle..."
    }
}

struct SyncerViewModel {
    
    let syncer: StandardSyncer
    
    let status: SignalProducer<String, NoError>
    let host: SignalProducer<String, NoError>
    let projectName: SignalProducer<String, NoError>
    let initialProjectName: String
    let buildTemplateName: SignalProducer<String, NoError>
    let editButtonTitle: SignalProducer<String, NoError>
    let editButtonEnabled: SignalProducer<Bool, NoError>
    let controlButtonTitle: SignalProducer<String, NoError>
    
    typealias PresentEditViewControllerType = (ConfigTriplet) -> ()
    let presentEditViewController: PresentEditViewControllerType
    
    init(syncer: StandardSyncer, presentEditViewController: PresentEditViewControllerType) {
        self.syncer = syncer
        self.presentEditViewController = presentEditViewController
        
        let active = syncer.activeSignalProducer.producer
        let state = syncer.state.producer
        
        self.status = combineLatest(state, active)
            .map { SyncerStatePresenter.stringForState($0.0, active: $0.1) }
        
        self.host = SignalProducer(value: syncer.xcodeServer)
            .map { $0.config.host ?? "[No Xcode Server]" }
        
        self.projectName = SignalProducer(value: syncer.project)
            .map { $0.workspaceMetadata?.projectName ?? "[No Project]" }
        //pull initial project name for sorting
        self.initialProjectName = syncer.project.workspaceMetadata?.projectName ?? ""
        
        self.buildTemplateName = SignalProducer(value: syncer.buildTemplate.name)
        self.editButtonTitle = SignalProducer(value: "View")
        self.editButtonEnabled = SignalProducer(value: true)
        self.controlButtonTitle = active.map { $0 ? "Stop" : "Start" }
    }
    
    func viewButtonClicked() {
        
        //present the edit window
        let triplet = self.syncer.configTriplet
        self.presentEditViewController(triplet)
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
    
    
}

