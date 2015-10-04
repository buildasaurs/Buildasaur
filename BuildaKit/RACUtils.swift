//
//  RACUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa

//func flattenArray<T, E>(inProducer: SignalProducer<[T], E>) -> SignalProducer<T, E> {
//    
//    return inProducer.flatMap(.Merge) { (vals: [T]) -> SignalProducer<T, E> in
//        return SignalProducer { sink, _ in
//            vals.forEach { sendNext(sink, $0) }
//            sendCompleted(sink)
//        }
//    }
//}

extension SignalProducer {
    
    public func ignoreErrors() -> SignalProducer<T, NoError> {
        return self.flatMapError { _ in
            return SignalProducer<T, NoError> { _, _ in }
        }
    }
}

