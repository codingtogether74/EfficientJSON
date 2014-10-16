//
//  User.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/13/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

struct User1: JSONDecodable, Printable {
    let id: Int
    let name: String
    let email: String?

    
    var description : String {
        return "User1 { id = \(id), name = \(name), email = \(email)}"
    }
    static func create(id: Int)(name: String)(email: String) -> User1 {
        return User1(id: id, name: name, email: email)
    }
    
    static func decode1(json: JSON) -> User1? {
        return JSONObject(json) >>> { d in
            User1.create <^>
                d["id"]    >>> JSONInt    <*>
                d["name"]  >>> JSONString <*>
                d["email"] >>> JSONString
        }
    }
    
    static func stringResult(result: Result<User1> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}


struct User: Printable {
    let id: Int
    let name: String
    let email: String?
    var description : String {
        return "User { id = \(id), name = \(name), email = \(email)}"
    }

    static func create(id: Int)(name: String)(email: String) -> User {
        return User(id: id, name: name, email: email)
    }
    
    static func stringResult(result: Result<User> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
              return "\(box.value.description)"
        }
    }

    static func decode(json: JSON) -> Result<User> {
        let user = JSONObject(json) >>> { dict in
            User.create <^>
                dict["id"]    >>> JSONInt    <*>
                dict["name"]  >>> JSONString <*>
                dict["email"] >>> JSONString
        }
        return resultFromOptional(user, NSError(localizedDescription: "Отсутствуют компоненты User")) // custom error message
    }
   
}
func getUser0(jsonOptional: NSData?, callback: (User) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
           if let name = dict["name"] as AnyObject? as? String {
            if let id = dict["id"] as AnyObject? as? Int { //there is a bug that forces us to cast to AnyObject? first
                if let email = dict["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                    callback(user)
                }
            }
        }
    }
}

func getUser1(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    if let dict =  json as? Dictionary<String,AnyObject> {
        if let name = dict["name"] as AnyObject? as? String {
            if let id = dict["id"] as AnyObject? as? Int { //there is a bug that forces us to cast to AnyObject? first
                if let email = dict["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                    callback(.Value(Box(user)))
                    return
                }
            }
        }
    }
    
    callback(.Error(NSError()))
}

func getUser4(jsonOptional: NSData?, callback: (Result<User>) -> ()) {

    let result = decodeJSON1(jsonOptional!)
                                >>> User.decode
    callback(result)
    
}

func getUser5(jsonOptional: NSData?, callback: (Result<User1>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON1 >>> decodeObject >>> callback
}
