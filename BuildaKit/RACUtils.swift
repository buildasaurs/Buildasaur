//
//  RACUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa

public func flattenArray<T, E>(inProducer: SignalProducer<[T], E>) -> SignalProducer<T, E> {
    
    return inProducer.flatMap(.Merge) { (vals: [T]) -> SignalProducer<T, E> in
        return SignalProducer { sink, _ in
            vals.forEach { sendNext(sink, $0) }
            sendCompleted(sink)
        }
    }
}

extension SignalProducer {
    
    public func ignoreErrors(action: ((E) -> ())? = nil) -> SignalProducer<T, NoError> {
        return self.flatMapError {
            action?($0)
            return SignalProducer<T, NoError> { _, _ in }
        }
    }
    
    //only sends values when condition has value true
    public func forwardIf(condition: SignalProducer<Bool, E>) -> SignalProducer<T, E> {
        return combineLatest(self, condition).map { (value: T, condition: Bool) -> T? in
            return condition ? value : nil
        }.ignoreNil()
    }
}

internal func repack<A, B, C, D, E, F, G, H, I, J, K>(t: (A, B, C, D, E, F, G, H, I, J), value: K) -> (A, B, C, D, E, F, G, H, I, J, K) {
    return (t.0, t.1, t.2, t.3, t.4, t.5, t.6, t.7, t.8, t.9, value)
}

/// Combines the values of all the given producers, in the manner described by
/// `combineLatestWith`.
@warn_unused_result(message="Did you forget to call `start` on the producer?")
public func combineLatest<A, B, C, D, E, F, G, H, I, J, K, Error>(a: SignalProducer<A, Error>, _ b: SignalProducer<B, Error>, _ c: SignalProducer<C, Error>, _ d: SignalProducer<D, Error>, _ e: SignalProducer<E, Error>, _ f: SignalProducer<F, Error>, _ g: SignalProducer<G, Error>, _ h: SignalProducer<H, Error>, _ i: SignalProducer<I, Error>, _ j: SignalProducer<J, Error>, _ k: SignalProducer<K, Error>) -> SignalProducer<(A, B, C, D, E, F, G, H, I, J, K), Error> {
    return combineLatest(a, b, c, d, e, f, g, h, i, j)
        .combineLatestWith(k)
        .map(repack)
}

internal func repack<A, B, C, D, E, F, G, H, I, J, K, L>(t: (A, B, C, D, E, F, G, H, I, J, K), value: L) -> (A, B, C, D, E, F, G, H, I, J, K, L) {
    return (t.0, t.1, t.2, t.3, t.4, t.5, t.6, t.7, t.8, t.9, t.10, value)
}

/// Combines the values of all the given producers, in the manner described by
/// `combineLatestWith`.
@warn_unused_result(message="Did you forget to call `start` on the producer?")
public func combineLatest<A, B, C, D, E, F, G, H, I, J, K, L, Error>(a: SignalProducer<A, Error>, _ b: SignalProducer<B, Error>, _ c: SignalProducer<C, Error>, _ d: SignalProducer<D, Error>, _ e: SignalProducer<E, Error>, _ f: SignalProducer<F, Error>, _ g: SignalProducer<G, Error>, _ h: SignalProducer<H, Error>, _ i: SignalProducer<I, Error>, _ j: SignalProducer<J, Error>, _ k: SignalProducer<K, Error>, _ l: SignalProducer<L, Error>) -> SignalProducer<(A, B, C, D, E, F, G, H, I, J, K, L), Error> {
    return combineLatest(a, b, c, d, e, f, g, h, i, j, k)
        .combineLatestWith(l)
        .map(repack)
}

