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
    func didSelectProjectConfig(config: ProjectConfig)
}

extension ProjectConfig {
    
    var name: String {
        let fileWithExtension = (self.url as NSString).lastPathComponent
        let file = (fileWithExtension as NSString).stringByDeletingPathExtension
        return file
    }
}

class EmptyProjectViewController: EditableViewController {
    
    //for cases when we're editing an existing syncer - show the
    //right preference.
    var existingConfigId: RefType?
    
    weak var emptyProjectDelegate: EmptyProjectViewControllerDelegate?
    
    @IBOutlet weak var existingProjectsPopup: NSPopUpButton!
    
    private var projectConfigs: [ProjectConfig] = []
    private var selectedConfig = MutableProperty<ProjectConfig?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDataSource()
        self.setupPopupAction()
        self.setupEditableStates()
        
        //select if existing config is being edited
        let index: Int
        if let configId = self.existingConfigId {
            let ids = self.projectConfigs.map { $0.id }
            index = ids.indexOf(configId) ?? 0
        } else {
            index = 0
        }
        self.selectItemAtIndex(index)
        self.existingProjectsPopup.selectItemAtIndex(index)
    }
    
    func addNewString() -> String {
        return "Add new Xcode Project..."
    }
    
    func newConfig() -> ProjectConfig {
        return ProjectConfig()
    }
    
    override func shouldGoNext() -> Bool {
        
        var current = self.selectedConfig.value!
        if current.url.isEmpty {
            //just new config, needs to be picked
            guard let picked = self.pickNewProject() else { return false }
            current = picked
        }
        
        self.didSelectProjectConfig(current)
        return super.shouldGoNext()
    }
    
    private func setupEditableStates() {
        
        self.nextAllowed <~ self.selectedConfig.producer.map { $0 != nil }
    }
    
    private func selectItemAtIndex(index: Int) {
        
        let configs = self.projectConfigs
        
        //                                      last item is "add new"
        let config = (index == configs.count) ? self.newConfig() : configs[index]
        self.selectedConfig.value = config
    }
    
    private func setupPopupAction() {
        
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.existingProjectsPopup.indexOfSelectedItem
                sself.selectItemAtIndex(index)
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
            var configDisplayNames = newConfigs.map { $0.name }
            configDisplayNames.append(self?.addNewString() ?? ":(")
            popup.addItemsWithTitles(configDisplayNames)
        }
    }
    
    private func didSelectProjectConfig(config: ProjectConfig) {
        Log.verbose("Selected \(config.url)")
        self.emptyProjectDelegate?.didSelectProjectConfig(config)
    }
    
    private func pickNewProject() -> ProjectConfig? {
        
        if let url = StorageUtils.openWorkspaceOrProject() {
            
            do {
                try self.storageManager.checkForProjectOrWorkspace(url)
                var config = ProjectConfig()
                config.url = url.path!
                return config
            } catch {
                //local source is malformed, something terrible must have happened, inform the user this can't be used (log should tell why exactly)
                UIUtils.showAlertWithText("Couldn't add Xcode project at path \(url.absoluteString), error: \((error as NSError).localizedDescription).", style: NSAlertStyle.CriticalAlertStyle, completion: { (resp) -> () in
                    //
                })
            }
        } else {
            //user cancelled
        }
        return nil
    }
}

