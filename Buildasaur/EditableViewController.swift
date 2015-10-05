//
//  EditableViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaUtils
import BuildaKit
import ReactiveCocoa

class EditableViewController: NSViewController {
    
    var storageManager: StorageManager!
    let editingAllowed = MutableProperty<Bool>(true)
    let editing = MutableProperty<Bool>(true)
    
    let nextAllowed = MutableProperty<Bool>(true)
    let previousAllowed = MutableProperty<Bool>(true)
    
    //for overriding
    
    func willGoNext() {
        //
    }
    
    func willGoPrevious() {
        //
    }
}
