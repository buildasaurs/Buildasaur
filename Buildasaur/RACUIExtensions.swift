//
//  RACUIExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import Cocoa
import ReactiveCocoa

//taken from https://github.com/ColinEberhardt/ReactiveTwitterSearch/blob/82ab9d2595b07cbefd4c917ae643b568dd858119/ReactiveTwitterSearch/Util/UIKitExtensions.swift

//book keeping

func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, factory: () -> T) -> T {
    if let object = objc_getAssociatedObject(host, key) as? T {
        return object
    }
    
    let associatedProperty = factory()
    objc_setAssociatedObject(host, key, associatedProperty, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    return associatedProperty
}

func lazyMutableProperty<T>(host: AnyObject, key: UnsafePointer<Void>, setter: (T) -> (), getter: () -> T) -> MutableProperty<T> {
    return lazyAssociatedProperty(host, key: key) {
        let property = MutableProperty<T>(getter())
        property.producer
            .startWithNext { setter($0) }
        return property
    }
}

struct AssociationKey {
    static var stringValue: UInt8 = 1
    static var title: UInt8 = 2
    static var enabled: UInt8 = 3
    static var hidden: UInt8 = 4
    static var animating: UInt8 = 5
    static var image: UInt8 = 6
}

//the good stuff

extension NSTextField {
    
    public var rac_stringValue: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.stringValue, setter: { [weak self] in self?.stringValue = $0 }, getter: { [weak self] in self?.stringValue ?? "" })
    }
}

extension NSButton {
    
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.title, setter: { [weak self] in self?.title = $0 }, getter: { [weak self] in self?.title ?? "" })
    }
}

extension NSControl {
    
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.enabled, setter: { [weak self] in self?.enabled = $0 }, getter: { [weak self] in self?.enabled ?? false })
    }
    
    //not sure about the memory management here
    public var rac_text: SignalProducer<String, NoError> {
        return self
            .rac_textSignal()
            .toSignalProducer()
            .map { $0 as? String }
            .ignoreNil()
            .ignoreErrors()
    }
}

extension NSView {
    
    public var rac_hidden: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.hidden, setter: { [weak self] in self?.hidden = $0 }, getter: { [weak self] in self?.hidden ?? false })
    }
}

extension NSProgressIndicator {
    
    public var rac_animating: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.animating, setter: { [weak self] in $0 ? self?.startAnimation(nil) : self?.stopAnimation(nil) }, getter: { false })
    }
}

extension NSImageView {
    
    public var rac_image: MutableProperty<NSImage?> {
        return lazyMutableProperty(self, key: &AssociationKey.image, setter: { [weak self] in self?.image = $0 }, getter: { [weak self] in self?.image })
    }
}









