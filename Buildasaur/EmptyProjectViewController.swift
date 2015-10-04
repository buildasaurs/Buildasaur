//
//  StatusProjectEmptyViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit

class StatusProjectEmptyViewController: StorableViewController {
    
    weak var emptyProjectDelegate: StatusProjectEmptyViewControllerDelegate?
    
    @IBOutlet weak var addProjectButton: NSButton!
    
    @IBAction func addProjectButtonTapped(sender: AnyObject) {
        
        if let url = StorageUtils.openWorkspaceOrProject() {
            
            do {
                try self.storageManager.checkForProjectOrWorkspace(url)
                self.emptyProjectDelegate?.detectedProjectOrWorkspaceAtUrl(url)
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

protocol StatusProjectEmptyViewControllerDelegate: class {
    func detectedProjectOrWorkspaceAtUrl(url: NSURL)
}
