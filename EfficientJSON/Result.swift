
//
//  Result.swift
//  swiftz
//
//  Created by Maxwell Swadling on 9/06/2014.
//  Copyright (c) 2014 Maxwell Swadling. All rights reserved.
//

// Result is similar to an Either, except the Left side is always an NSError.

import Foundation

public enum Result<V> {
    case Error(NSError)
    case Value(Box<V>)
    
    public init(_ e: NSError?, _ v: V) {
        if let ex = e {
            self = Result.Error(ex)
        } else {
            self = Result.Value(Box(v))
        }
    }

    public func fold<B>(value: B, f: V -> B) -> B {
        switch self {
        case Error(_): return value
        case let Value(v): return f(v.value)
        }
    }
    
    public static func error(e: NSError) -> Result<V> {
        return .Error(e)
    }
    
    public static func value(v: V) -> Result<V> {
        return .Value(Box(v))
    }
}

// Equatable
public func ==<V: Equatable>(lhs: Result<V>, rhs: Result<V>) -> Bool {
    switch (lhs, rhs) {
    case let (.Error(l), .Error(r)) where l == r: return true
    case let (.Value(l), .Value(r)) where l.value == r.value: return true
    default: return false
    }
}

public func !=<V: Equatable>(lhs: Result<V>, rhs: Result<V>) -> Bool {
    return !(lhs == rhs)
}
