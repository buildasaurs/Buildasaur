//
//  EmptyXcodeServerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit
import BuildaUtils
import XcodeServerSDK
import ReactiveCocoa

protocol EmptyXcodeServerViewControllerDelegate: class {
    func didSelectXcodeServerConfig(config: XcodeServerConfig)
}

class EmptyXcodeServerViewController: EditableViewController {
    
    //for cases when we're editing an existing syncer - show the
    //right preference.
    var existingConfigId: RefType?
    
    weak var emptyServerDelegate: EmptyXcodeServerViewControllerDelegate?
    
    @IBOutlet weak var existingXcodeServersPopup: NSPopUpButton!

    private var xcodeServerConfigs: [XcodeServerConfig] = []
    private var selectedConfig = MutableProperty<XcodeServerConfig?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDataSource()
        self.setupPopupAction()
        self.setupEditableStates()
        
        //select
        let index: Int
        if let configId = self.existingConfigId {
            let ids = self.xcodeServerConfigs.map { $0.id }
            index = ids.indexOf(configId) ?? 0
        } else {
            index = 0
        }
        self.selectItemAtIndex(index)
    }
    
    func addNewString() -> String {
        return "Add new Xcode Server..."
    }
    
    func newConfig() -> XcodeServerConfig {
        return XcodeServerConfig()
    }
    
    override func willGoNext() {
        super.willGoNext()
        
        self.didSelectXcodeServer(self.selectedConfig.value!)
    }
    
    private func setupEditableStates() {
        
        self.nextAllowed <~ self.selectedConfig.producer.map { $0 != nil }
    }
    
    private func selectItemAtIndex(index: Int) {
        
        let configs = self.xcodeServerConfigs
        
        //                                      last item is "add new"
        let config = (index == configs.count) ? self.newConfig() : configs[index]
        self.selectedConfig.value = config
    }
    
    private func setupPopupAction() {
        
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.existingXcodeServersPopup.indexOfSelectedItem
                sself.selectItemAtIndex(index)
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.existingXcodeServersPopup.rac_command = toRACCommand(action)
    }
    
    private func setupDataSource() {

        let configsProducer = self.storageManager.serverConfigs.producer
        let allConfigsProducer = configsProducer
            .map { Array($0.values) }
            .map { configs in configs.sort { $0.host < $1.host } }
        allConfigsProducer.startWithNext { [weak self] newConfigs in
            guard let sself = self else { return }
            
            sself.xcodeServerConfigs = newConfigs
            let popup = sself.existingXcodeServersPopup
            popup.removeAllItems()
            var configDisplayNames = newConfigs.map { "\($0.host) (\($0.user ?? String()))" }
            configDisplayNames.append(self?.addNewString() ?? ":(")
            popup.addItemsWithTitles(configDisplayNames)
        }
    }
    
    private func didSelectXcodeServer(config: XcodeServerConfig) {
        Log.verbose("Selected \(config.host)")
        self.emptyServerDelegate?.didSelectXcodeServerConfig(config)
    }
}

