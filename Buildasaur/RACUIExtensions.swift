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
import Result

//taken from https://github.com/ColinEberhardt/ReactiveTwitterSearch/blob/82ab9d2595b07cbefd4c917ae643b568dd858119/ReactiveTwitterSearch/Util/UIKitExtensions.swift

//book keeping

func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, factory: () -> T) -> T {
    
    let obj: T? = getAssociatedProperty(host, key: key) as? T
    if let object = obj {
        return object
    }
    
    let associatedProperty = factory()
    setAssociatedProperty(host, key: key, value: associatedProperty)
    return associatedProperty
}

func setAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, value: T) {
    objc_setAssociatedObject(host, key, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
}

func getAssociatedProperty(host: AnyObject, key: UnsafePointer<Void>) -> AnyObject! {
    return objc_getAssociatedObject(host, key)
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
    static var on: UInt8 = 7
    static var on_action: UInt8 = 8
    static var placeholder: UInt8 = 9
    static var doubleValue: UInt8 = 10
}

//the good stuff

extension NSTextField {
    
    public var rac_stringValue: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.stringValue, setter: { [weak self] in self?.stringValue = $0 }, getter: { [weak self] in self?.stringValue ?? "" })
    }
    
    public var rac_doubleValue: MutableProperty<Double> {
        return lazyMutableProperty(self, key: &AssociationKey.doubleValue, setter: { [weak self] in self?.doubleValue = $0 }, getter: { [weak self] in self?.doubleValue ?? 0 })
    }
    
    public var rac_placeholderString: MutableProperty<String?> {
        return lazyMutableProperty(self, key: &AssociationKey.placeholder, setter: { [weak self] in self?.placeholderString = $0 }, getter: { [weak self] in self?.placeholderString })
    }
}

extension NSButton {
    
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.title, setter: { [weak self] in self?.title = $0 }, getter: { [weak self] in self?.title ?? "" })
    }
    
    public var rac_on: SignalProducer<Bool, NoError> {
        
        let on = lazyMutableProperty(self, key: &AssociationKey.on, setter: { [weak self] in self?.on = $0 }, getter: { [weak self] in self?.on ?? false })
        
        let action = Action<AnyObject?, AnyObject, NoError> {
            input in
            let button = input as! NSButton
            return SignalProducer { sink, _ in
                on.value = button.on
                sink.sendCompleted()
            }
        }
        
        self.rac_command = toRACCommand(action)
        
        return on.producer
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









