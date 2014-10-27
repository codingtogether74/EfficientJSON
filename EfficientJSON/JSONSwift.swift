//
//  JSONSwift.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 8/7/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>


// functions
func dictionary(input: JSONDictionary, key: String) ->  JSONDictionary? {
    return input[key] >>> { $0 as? JSONDictionary }
}

func array(input: JSONDictionary, key: String) ->  JSONArray? {
    return input[key] >>> { $0 as?  JSONArray}                     
}

func JSONString(object: JSON) -> String? {
    return object as? String
}

func JSONInt(object: JSON) -> Int? {
    return object as? Int
}

func JSONBool(object: JSON) -> Bool? {
    return object as? Bool
}
func JSONObject(object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

func JSONCollection(object: JSON) -> JSONArray? {
    return object as? JSONArray
}
//------------Functions------------------

public func flatten<A>(array: [A?]) -> [A] {
    var list: [A] = []
    for item in array {
        if let i = item {
            list.append(i)
        }
    }
    return list
}

public func pure<A>(a: A) -> A? {
    return .Some(a)
}

func _JSONParse<A>(json: JSON) -> A? {
    return json as? A
}

func extract<A>(json: JSONDictionary, key: String) -> A? {
    return json[key] >>> _JSONParse
}

func extractPure<A>(json: JSONDictionary, key: String) -> A?? {
    return pure(json[key] >>> _JSONParse)
}
// ----------------operators Optional ----

infix operator >>> { associativity left precedence 150 }
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

public func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

public func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return (f(x))
    } else {
        return .None
    }
}

public func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}

//-------- convenience initializer for  NSError class -----

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}

//------------------ From Optionals to Result -----

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}
//------------------ protocol  JSONDecodable -----

protocol JSONDecodable {
    class func decode1(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode1(json), NSError(localizedDescription: "No some components of MODEL")) // custom error
}

//------------------ For Optionals JSON? -----

func decodeJSON(data: NSData?) -> JSON? {
    var jsonErrorOptional: NSError?
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    if let json: JSON = jsonOptional {
        return json
    } else {
        return .None
    }
}

//------------------ For Result<JSON> -----

func decodeJSON(data: NSData) -> Result<JSON> {
    let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
    return resultFromOptional(jsonOptional,
                       NSError(localizedDescription: "Wrong data for Parsing")) // error from NSJSONSerialization
}

// ----------------operators Result<A> ----

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}
//------------------------------------------



