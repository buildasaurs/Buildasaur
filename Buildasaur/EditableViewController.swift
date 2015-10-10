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
    
    var storageManager: StorageManager {
        return self.syncerManager.storageManager
    }
    var syncerManager: SyncerManager!
    let editingAllowed = MutableProperty<Bool>(true)
    let editing = MutableProperty<Bool>(true)
    
    let nextAllowed = MutableProperty<Bool>(true)
    let cancelAllowed = MutableProperty<Bool>(true)
    
    typealias ActionSignal = Signal<Void, NoError>
    typealias AnimatableSignal = Signal<Bool, NoError>
    private typealias ActionObserver = ActionSignal.Observer
    private typealias AnimatableObserver = AnimatableSignal.Observer
    
    var wantsNext: AnimatableSignal!
    var wantsPrevious: ActionSignal!
    
    private var sinkNext: AnimatableObserver!
    private var sinkPrevious: ActionObserver!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let (wn, sn) = AnimatableSignal.pipe()
        self.wantsNext = wn
        self.sinkNext = sn
        let (wp, sp) = ActionSignal.pipe()
        self.wantsPrevious = wp
        self.sinkPrevious = sp
    }
    
    //call from inside of controllers, e.g.
    //when shouldGoNext starts validating and it succeeds some time later,
    //call goNext to finish going next. otherwise don't call
    //and force user to fix the problem.
    
    final func goNext(animated animated: Bool = false) {
        sendNext(self.sinkNext, animated)
    }
    
    final func goPrevious() {
        sendNext(self.sinkPrevious, ())
    }

    //for overriding

    func shouldGoNext() -> Bool {
        return true
    }
    
    func shouldGoPrevious() -> Bool {
        return true
    }
    
    func shouldCancel() -> Bool {
        return true
    }
}
