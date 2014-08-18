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

struct Blog: Printable {
    let id: Int
    let name: String
    let needsPassword : Bool
    let url: NSURL
    var description : String {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
    }

    static func create(id: Int)(name: String)(needsPassword: Int)(url:String) -> Blog {
            return Blog(id: id, name: name, needsPassword: Bool(needsPassword), url: toURL(url))
    }

    static func decode(json: JSON) -> Result<Blog> {
        let blog = JSONObject(json) >>> { dict in
            Blog.create <^>
                dict["id"]    >>> JSONInt    <*>
                dict["name"] >>> JSONString <*>
                dict["needspassword"] >>> JSONInt <*>
                dict["url"] >>> JSONString
        }
        return resultFromOptional(blog, NSError()) // custom error message
    }
}
/*
enum Result<A> {
    case None
    case Value(A)
    
}

*/
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

infix operator >>> { associativity left precedence 150 }

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

public func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return (f(x))
    } else {
        return .None
    }
}
/*
func <^><A, B>(f: A -> B?, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}
*/
func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}

func decodeJSON(data: NSData) -> JSON? {
    var jsonErrorOptional: NSError?
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    if let json: JSON = jsonOptional {
        return json
    } else {
        return .None
    }
}

func getUser0(jsonOptional: NSData?) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)

    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"] as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            let id : AnyObject? = blogInfo["id"]
                            let name : AnyObject? = blogInfo["name"]
                            let needspassword : AnyObject? = blogInfo["needspassword"]
                            let url : AnyObject? = blogInfo["url"]
                            
                                                           println("Blog ID: \(id)")
                                                           println("Blog Name: \(name)")
                                                           println("Blog Needs Password: \(needspassword)")
                                                           println("Blog URL: \(url)")
                        }
                    }
                }
            }
        }
    }
   

}

func getUser1(jsonOptional: NSData?, callback: (Blog) -> ()) {
   var jsonErrorOptional: NSError?
   let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"] as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            
                            if let id =  blogInfo["id"] as AnyObject? as? Int { // Currently in beta 5 there is a bug that forces us to cast to AnyObject? first
                                if let name = blogInfo["name"] as AnyObject? as? String {
                                    if let needPassword = blogInfo["needspassword"] as AnyObject? as? Bool {
                                        if let url = blogInfo["url"] as AnyObject? as? String {
                                            let user = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url))
                                            callback(user)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

func getUser2(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        //       callback(.Error(err))
        callback(.Error(err))
        return
    }
    
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"] as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            if let id =  blogInfo["id"] as AnyObject? as? Int { // Currently in beta 5 there is a bug that forces us to cast to AnyObject? first
                                if let name = blogInfo["name"] as AnyObject? as? String {
                                    if let needPassword = blogInfo["needspassword"] as AnyObject? as? Bool {
                                        if let url = blogInfo["url"] as AnyObject? as? String {
                                            let blog = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url))
                                            callback(.Value(Box(blog)))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
   
    callback(.Error(NSError()))
}

func getUser3(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        //       callback(.Error(err))
        callback(.Error(err))
        return
    }
    
    
    if let dict =   jsonObject >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
                if let collection = blogs["blog"] >>> JSONCollection {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog >>> JSONObject  {
                            if let id =  blogInfo["id"] >>> JSONInt {
                                if let name = blogInfo["name"] >>> JSONString {
                                    if let needPassword = blogInfo["needspassword"] >>> JSONInt {
                                        if let url = blogInfo["url"] >>> JSONString {
                                            let blog = Blog(id: id, name: name, needsPassword: Bool(needPassword) , url: NSURL(string:url))
                                            callback(.Value(Box(blog)))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    
    callback(.Error(NSError()))
    
}

func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)
}

func getUser4(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional,
           options: NSJSONReadingOptions(0),
             error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }

    
    if let dict =   jsonObject >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
            if let collection = blogs["blog"] >>> JSONCollection {
                for blog : AnyObject in collection {
                  if let blogInfo = blog >>> JSONObject                     {
                        println("\(blogInfo)")
                        let blog1 = Blog.create  <^>
                            blogInfo["id"] >>> JSONInt <*>
                            blogInfo["name"] >>> JSONString <*>
                            blogInfo["needspassword"] >>> JSONInt <*>
                            blogInfo["url"] >>> JSONString
                  
                        if let u = blog1 {
                            callback(.Value(Box(u)))
                        } else {
                             callback(.Error(NSError()))
                        }
                    }
                }
            }
        }
    }
}

func getUser5(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    
    if let dict =   jsonObject >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
            if let collection = blogs["blog"] >>> JSONCollection {
                for blog : AnyObject in collection {
                    let blogInfo:()? = blog >>> JSONObject  >>> Blog.decode >>> callback
                  
                  /*  {
                        callback ( Blog.decode (blogInfo ))
                    }*/
                    
                }
            }
        }
    }
}

func getUser6(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {

    if let dict =  jsonOptional >>> decodeJSON  >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
            if let collection = blogs["blog"] >>> JSONCollection {
                for blog : AnyObject in collection {
                    let blogInfo:()? = blog >>> JSONObject  >>> Blog.decode >>> callback

                }
            }
        }
    }
}

