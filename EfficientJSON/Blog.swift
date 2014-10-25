//
//  Blog.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/16/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation
func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)!
}

struct Blog: Printable,JSONDecodable {
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
    
    static func decode1(json: JSON) -> Blog? {   ///---------------decode1
        return  JSONObject(json) >>> { dict in
            Blog.create <^>
                dict["id"]    >>> JSONInt    <*>
                dict["name"] >>> JSONString <*>
                dict["needspassword"] >>> JSONInt <*>
                dict["url"] >>> JSONString
        }
    }

}
// ----Структура Blogs ----

struct Blogs: Printable,JSONDecodable {
    
    var blogs : [Blog]
    
    var description :String  { get {
        var str: String = ""
        for blog in self.blogs {
            str = str +  "\(blog) \n"
        }
        return str
        }
    }
    
    init(blogs1: [Blog]){
        self.blogs = blogs1
    }
    static func create(blogs: [Blog]) -> Blogs {
        return Blogs(blogs1: blogs)
    }
    
    static func decode1(json: JSON) -> Blogs? {           //------------------decode1
        return create <*> JSONObject(json) >>> {
            dictionary ($0,"blogs") >>> {
                array($0, "blog") >>> {
                    flatten($0.map(Blog.decode1) )}}}
        
    }
}
// ---- Конец структуры Blogs----


func getBlog0(jsonOptional: NSData?) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
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

func getBlog1(jsonOptional: NSData?, callback: (Blog) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
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
                                            let user = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url)!)
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

func getBlog2(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        //       callback(.Error(err))
        callback(.Error(err))
        return
    }
    
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"]  as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            if let id =  blogInfo["id"] as AnyObject? as? Int { // Currently in beta 5 there is a bug that forces us to cast to AnyObject? first
                                if let name = blogInfo["name"] as AnyObject? as? String {
                                    if let needPassword = blogInfo["needspassword"] as AnyObject? as? Bool {
                                        if let url = blogInfo["url"] as AnyObject? as? String {
                                            let blog = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url)!)
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

func getBlog3(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
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
                                        let blog = Blog(id: id, name: name, needsPassword: Bool(needPassword) , url: NSURL(string:url)!)
                                        callback(.Value(Box(blog)))
                                        return
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


func getBlog4(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
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

func getBlog5(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
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
                    
                }
            }
        }
    }
}

func getBlog6(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    if let dict =  jsonOptional >>> decodeJSON  >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
            if let collection = blogs["blog"] >>> JSONCollection {
                for blog : AnyObject in collection {
                    let blogInfo:()? = blog >>> JSONObject  >>>
                        Blog.decode >>> callback
                }
            }
        }
    }
}

func getBlog7(jsonOptional: NSData?, callback: ([Result<Blog>]) -> ()) {
    let json =  jsonOptional >>> decodeJSON  >>> JSONObject
    let blogs: ()? = dictionary(json!,"blogs") >>> {
                             array($0, "blog") >>> {flatten($0.map(Blog.decode))
                                } >>> callback
    }
}

func getBlog8(jsonOptional: NSData?, callback: ([Result<Blog>]) -> ()) {
    let json: ()? =  jsonOptional >>> decodeJSON  >>> JSONObject >>> {
                                         dictionary ($0,"blogs") >>> {
                                               array($0, "blog") >>> {flatten($0.map(Blog.decode))
                                                  } >>> callback
        }
    }
}

func getBlog9(jsonOptional: NSData?, callback: ([Result<Blog>]) -> ()) {
    let json: ()? =  jsonOptional >>> decodeJSON  >>> JSONObject >>> {
                                         dictionary ($0,"blogs") >>> {
                                               array($0, "blog") >>> {flatten($0.map(Blog.decode ))
                                                } >>> callback
        }
    }
}

func getBlog10(jsonOptional: NSData?, callback: ([Result<Blog>]) -> ()) {
    let json: ()? =  jsonOptional >>> decodeJSON  >>> decodeObjectBlogs >>> callback
}

func decodeObjectBlogs(json: JSON) -> [Result<Blog>]? {
    return  json  >>> JSONObject >>> {
        dictionary ($0,"blogs") >>> {
            array($0, "blog") >>> {flatten($0.map(Blog.decode) )}}}
    
}

// ----- использована структура Blogs -----КЛАСС!!!

func getBlog11(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let json: ()? =  jsonResult  >>> decodeJSON  >>> decodeObject >>> callback
}



