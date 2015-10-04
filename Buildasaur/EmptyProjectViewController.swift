//
//  EmptyProjectViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import ReactiveCocoa
import BuildaUtils

protocol EmptyProjectViewControllerDelegate: class {
    func selectedProjectConfig(config: ProjectConfig)
}

extension ProjectConfig {
    
    var name: String {
        return (self.url as NSString).lastPathComponent
    }
}

class EmptyProjectViewController: StorableViewController {
    
    weak var emptyProjectDelegate: EmptyProjectViewControllerDelegate?
    
    @IBOutlet weak var existingProjectsPopup: NSPopUpButton!

    private var projectConfigs: [ProjectConfig] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDataSource()
        self.setupPopupAction()
    }

    private func setupPopupAction() {
        
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.existingProjectsPopup.indexOfSelectedItem
                let configs = sself.projectConfigs
                let config = configs[index]
                sself.didSelectProject(config)
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.existingProjectsPopup.rac_command = toRACCommand(action)
    }
    
    private func setupDataSource() {
        
        let configsProducer = self.storageManager.projectConfigs.producer
        let allConfigsProducer = configsProducer
            .map { Array($0.values) }
            .map { configs in configs.sort { $0.name < $1.name } }
        allConfigsProducer.startWithNext { [weak self] newConfigs in
            guard let sself = self else { return }
            
            sself.projectConfigs = newConfigs
            let popup = sself.existingProjectsPopup
            popup.removeAllItems()
            let configDisplayNames = newConfigs.map { $0.name }
            popup.addItemsWithTitles(configDisplayNames)
        }
    }
    
    private func didSelectProject(config: ProjectConfig) {
        Log.verbose("Selected Project \(config.name)")
        self.emptyProjectDelegate?.selectedProjectConfig(config)
    }
    
    @IBAction func addProjectButtonTapped(sender: AnyObject) {
        
        if let url = StorageUtils.openWorkspaceOrProject() {
            
            do {
                try self.storageManager.checkForProjectOrWorkspace(url)
                var config = ProjectConfig()
                config.url = url.path!
                self.didSelectProject(config)
            } catch {
                //local source is malformed, something terrible must have happened, inform the user this can't be used (log should tell why exactly)
                UIUtils.showAlertWithText("Couldn't add Xcode project at path \(url.absoluteString), error: \((error as NSError).localizedDescription).", style: NSAlertStyle.CriticalAlertStyle, completion: { (resp) -> () in
                    //
                })
            }
        } else {
            //user cancelled
        }
    }
}

