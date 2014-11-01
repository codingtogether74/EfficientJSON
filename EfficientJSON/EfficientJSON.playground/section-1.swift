// Playground - noun: a place where people can play

import Foundation

//---- Aticle http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

/*let parsedJSON : [String:AnyObject] = [
    "id": 1,
    "name": "Cool User",
    "email": "u.cool@example.com"
]
*/

struct User: Printable {
    let id: Int = 0
    let name: String = ""
    let email: String = ""
    var description : String {
        return "User { id = \(id), name = \(name), email = \(email)}"
    }
    static func create(id: Int)(name: String)(email: String) -> User {
        return User(id: id, name: name, email: email)
    }
    
}

//------- data for parsing User -----

let jsonString: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~ if-let  ~~~~~~~

func getUser0(jsonOptional: NSData?, callback: (User) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let json =  jsonObject as? Dictionary<String,AnyObject> {
        if let name = json["name"] as AnyObject? as? String {
            if let id = json["id"] as AnyObject? as? Int { //there is a bug that forces us to cast to AnyObject? first
                if let email = json["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                    callback(user)
                }
            }
        }
    }
}
//      ----- Test 1 ------

getUser0(jsonData){ user in
    println("\(user.description)")
    return // add for closure with one line

}

//~~~~~~~~~~~~~~~~ Handling Errors with enum Result<A> ~~~~~~~

final class Box<A> {
    let value: A
    
    init(_ value: A) {
        self.value = value
    }
}

enum Result<A> {
    case Error(NSError)
    case Value(Box<A>)

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
//--------------- For print Result  ---


func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}

//-------- convenience initializer for  NSError class -----

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
//--------------------- Return Result<User> ---------------

func getUser1(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }

    if let json =  jsonObject as? Dictionary<String,AnyObject> {
        if let name = json["name"] as AnyObject? as? String {
            if let id = json["id"] as AnyObject? as? Int { //there is a bug that forces us to cast to AnyObject? first
                if let email = json["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                     callback(.Value(Box(user)))
                    return
                 }
            }
        }
    }
    
    callback(.Error(NSError(localizedDescription: "no some components of User")))
}

//      ----- Test 1 - Correct data -----

let jsonString2: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData2: NSData? = jsonString2.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

getUser1(jsonData2 ){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Test 2 - incorrect data ( extra curly brace ) -----

let jsonString3: String = "{ {\"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

getUser1(jsonData3 ){ user in
    let a = stringResult(user)
    println("\(a)")

}

//      ----- Тест 3 - incorrect data ( instead of "id" there is  "id1") -----

let jsonString4: String = "{ \"id1\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData4: NSData? = jsonString4.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

getUser1(jsonData4 ){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ Eliminate Type Checking Tree ~~~~~~~
typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>

infix operator >>> { associativity left precedence 150 }

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func JSONString(object: JSON) -> String? {
    return object as? String
}

func JSONInt(object: JSON) -> Int? {
    return object as? Int
}

func JSONObject(object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

//--------------------- Use bind Operator >>> ---

func getUser2(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    if let json =  jsonObject >>> JSONObject {
        if let name = json["name"] >>> JSONString {
            if let id = json["id"] >>> JSONInt {
            if let email = json["email"] >>> JSONString {
                    let user:User = User(id: id, name: name, email: email)
                    callback(.Value(Box(user)))
                    return
                }
            }
        }
    }
    
    callback(.Error(NSError(localizedDescription: "no some components of User")))
}

//      ----- Test 1 - Correct Data-----

getUser2(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}
//----- New Operators  <^>   and  <*>  ---

infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}
//---------- curry our User’s init --------
//    static func create(id: Int)(name: String)(email: String) -> User {
//        return User(id: id, name: name, email: email)
//    }
//--------------------- Putting it all together ---

func getUser3(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    if let json =  jsonObject >>> JSONObject {
        let user = User.create <^>
            json["id"]    >>> JSONInt    <*>
            json["name"]  >>> JSONString <*>
            json["email"] >>> JSONString
        if let u = user {
            callback(.Value(Box(u)))
            return
        }
    }    
    callback(.Error(NSError(localizedDescription: "no some components of User")))
}

//      ----- Тest 1 - Correct Data -----

getUser3(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ Remove Multiple Returns with Bind ~~~~~~~

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}

func decodeJSON(data: NSData) -> Result<JSON> {
let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
return resultFromOptional(jsonOptional, NSError(localizedDescription: "Wrong data for Parsing")) // use the error from NSJSONSerialization or a custom error message
}


//--------------------- Operator >>> for Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}

//---------- Add init to Resul ---
//    init(_ error: NSError?, _ value: A) {
//        if let err = error {
//            self = .Error(err)
//        } else {
//            self = .Value(Box(value))
//        }
//    }

extension User {
    static func decode(json: JSON) -> Result<User> {
        let user = JSONObject(json) >>> { dict in
            User.create <^>
                dict["id"]    >>> JSONInt    <*>
                dict["name"]  >>> JSONString <*>
                dict["email"] >>> JSONString
        }
        return resultFromOptional(user, NSError(localizedDescription: "no some components of User")) // custom error message
    }
}

//--------------------- Putting it all together ---

func getUser4(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Wrong data for Parsing"))
    let user: ()? = jsonResult >>> decodeJSON
                                   >>> User.decode >>> callback
}

//      ----- Test 1 - Correct data -----

getUser4(jsonData){ user in
let a = stringResult(user)
println("\(a)")
}

//      ----- Тest 2 - incorrect data (extra curly brase) -----

getUser4(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Test 3 - incorrect data ( insread of "id" ve have "id1") -----

getUser4(jsonData4){ user in
    let a = stringResult(user)
    println("\(a)")
}

//========================== Use Generic =====

protocol JSONDecodable {
    class func decode(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode(json), NSError(localizedDescription: "no some components of Model")) // custom error
}

struct User1: JSONDecodable, Printable {
    let id: Int = 0
    let name: String = ""
    let email: String = ""
    
    var description : String {
        return "User1 { id = \(id), name = \(name), email = \(email)}"
    }
    static func create(id: Int)(name: String)(email: String) -> User1 {
        return User1(id: id, name: name, email: email)
    }

    static func decode(json: JSON) -> User1? {
        return JSONObject(json) >>> { d in
            User1.create <^>
                d["id"]    >>> JSONInt    <*>
                d["name"]  >>> JSONString <*>
                d["email"] >>> JSONString
        }
    }
    
    static func decode(json: JSON) -> Result<User1> {
        let user1 = JSONObject(json) >>> { dict in
            User1.create <^>
                dict["id"]    >>> JSONInt    <*>
                dict["name"]  >>> JSONString <*>
                dict["email"] >>> JSONString
        }
        return resultFromOptional(user1, NSError(localizedDescription: "no some components of Model User")) // custom error message
    }
}

func getUser5(jsonOptional: NSData?, callback: (Result<User1>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: "Wrong data for Parsing"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//      ----- Test 1 - Correct data -----

getUser5(jsonData){ user1 in
    let a = stringResult(user1)
    println("\(a)")
}

//      ----- Test 2 - incorrect data (extra curly brase) -----

getUser5(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Test 3 - incorrect data ( insread of "id" ve have "id1") -----

getUser5(jsonData4){ user in
    let a = stringResult(user)
    println("\(a)")
}
