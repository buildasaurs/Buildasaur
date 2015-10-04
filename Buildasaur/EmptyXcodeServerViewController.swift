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

class EmptyXcodeServerViewController: StorableViewController {
    
    weak var emptyServerDelegate: EmptyXcodeServerViewControllerDelegate?
    
    @IBOutlet weak var existingXcodeServersPopup: NSPopUpButton!

    private var xcodeServerConfigs: [XcodeServerConfig] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDataSource()
        self.setupPopupAction()
    }
    
    func setupPopupAction() {
        
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.existingXcodeServersPopup.indexOfSelectedItem
                let configs = sself.xcodeServerConfigs
                let config = configs[index]
                sself.didSelectXcodeServer(config)
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.existingXcodeServersPopup.rac_command = toRACCommand(action)
    }
    
    func setupDataSource() {

        let configsProducer = self.storageManager.serverConfigs.producer
        let allConfigsProducer = configsProducer
            .map { Array($0.values) }
            .map { configs in configs.sort { $0.host < $1.host } }
        allConfigsProducer.startWithNext { [weak self] newConfigs in
            guard let sself = self else { return }
            
            sself.xcodeServerConfigs = newConfigs
            let popup = sself.existingXcodeServersPopup
            popup.removeAllItems()
            let configDisplayNames = newConfigs.map { "\($0.host) (\($0.user ?? String()))" }
            popup.addItemsWithTitles(configDisplayNames)
        }
    }
    
    func didSelectXcodeServer(config: XcodeServerConfig) {
        Log.verbose("Selected Xcode Server \(config.host)")
        self.emptyServerDelegate?.didSelectXcodeServerConfig(config)
    }
    
    @IBAction func newXcodeServerClicked(sender: AnyObject) {
        let newConfig = XcodeServerConfig()
        self.didSelectXcodeServer(newConfig)
    }
}

