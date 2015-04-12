//
//  SetupViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit

protocol SetupViewControllerDelegate: class {
    
    func setupViewControllerDidSave(viewController: SetupViewController)
    func setupViewControllerDidCancel(viewController: SetupViewController)
}

class SetupViewController: NSViewController {
    
    var delegate: SetupViewControllerDelegate?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.reloadUI()
    }

    func reloadUI() {
        //gets overriden by subclasses
    }
    
    func pullDataFromUI(interactive: Bool) -> Bool {
        //gets overriden by subclasses
        return true
    }
    
    func willSave() {
        
    }
    
    func willCancel() {
        
    }
    
    func cancel() {
        self.willCancel()
        self.delegate?.setupViewControllerDidCancel(self)
        self.dismissController(nil)
    }
    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        
        let valid = self.pullDataFromUI(true)
        if valid {
            //save and dismiss
            self.willSave()
            self.delegate?.setupViewControllerDidSave(self)
            self.dismissController(nil)
            
        } else {
            //what's wrong should have been shown
        }
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.cancel()
    }
}
