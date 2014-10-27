
//
//  Result.swift
//  swiftz
//
//  Created by Maxwell Swadling on 9/06/2014.
//  Copyright (c) 2014 Maxwell Swadling. All rights reserved.
//

// Result is similar to an Either, except the Left side is always an NSError.

import Foundation

final class Box<A> {
    let value: A
    
     init(_ value: A) {
        self.value = value
    }
}

 enum Result<A> {
    case Error(NSError)
    case Value(Box<A>)
    
    var description : String {
        get {
            switch self{
            case let .Error(err):
                return "\(err.localizedDescription)"
            case let .Value(box):
                return "\(box.value)"
            }
        }
    }
    
    func takeValue() -> A? {
        switch self {
        case let .Value(v)  : return v.value 
        case let .Error(err): return nil
        }
    }

    
   func flatMap<B>(f:A -> Result<B>) -> Result<B> {
        switch self {
        case .Value(let v): return f(v.value)
        case .Error(let error): return .Error(error)
        }
    }
    
    
  init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(Box(value))
        }
    }
}
//--------------- For Print Result---


func stringResult<A: Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}

