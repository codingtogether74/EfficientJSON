// Playground - noun: a place where people can play
import Foundation

//---- Article http://robots.thoughtbot.com/real-world-json-parsing-with-swift

/*  

//----   All three components are here ---

let parsedJSON : [String:AnyObject] = [
"id": 1,
"name": "Cool User",
"email": "u.cool@example.com"
] 

ИЛИ

//----  Three is no  "email"

let parsedJSON1 : [String:AnyObject] = [
"id": 1,
"name": "Cool User"
]
*/

//------- Correct data for parsing User -----
//---------- Test 1 - Correct data  -----

let jsonString: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//----------- Test 2 - incorrect data ( extra curly brace ) -----

let jsonString1: String = "{ {\"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData1: NSData? = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//------- Test 3 - incorrect data ( instead of "id" there is  "id1") -----

let jsonString2: String = "{ \"id1\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData2: NSData? = jsonString2.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//-------- Тest 4 - incorrect data (there is no  email) -----

let jsonString3: String =  "{ \"id\": 1, \"name\":\"Cool user\" }"


let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)


//~~~~~~~~~~~~~~~~~~~~~~~ PARSING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>


//---------Functional programming OPERATOR >>>  <^>   and  <*>  ---

infix operator >>> { associativity left precedence 150 } // Bind
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

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

//~~~~~~~~~~ enum  Result<A> ~~~~~~~~~~~~

final class Box<A> {
    let value: A
    
    init(_ value: A) {
        self.value = value
    }
}

enum Result<A> {
    case Error(NSError)
    case Value(Box<A>)
        
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(Box(value))
        }
    }
}
//----------------------------- from Optional to Result<A> ---------

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}

//-------- convenience initializer for  NSError class -----

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
//------------------ For Result<JSON> -----

func decodeJSON(data: NSData) -> Result<JSON> {
    let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)

    return resultFromOptional(jsonOptional, NSError(localizedDescription: "JSON data is not correct")) // use the error from NSJSONSerialization or a custom error message
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
//--------------------- OPERATOR >>> для Result---


func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}

//--------------- For Print Result ---


 func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}

//~~~~~~~~~ ADD FUNCTIONS  ~~~~~~~~~~~~~~~~~~~

//------- flatten function ---

func flatten<A>(array: [A?]) -> [A] {
    var list: [A] = []
    for item in array {
        if let i = item {
            list.append(i)
        }
    }
    return list
}
//-------pure функцию ---

func pure<A>(a: A) -> A? {
    return .Some(a)
}
//---------------- Use Generics -----------

protocol JSONDecodable {
    class func decode1(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode1(json), NSError(localizedDescription: "no some components of User")) // custom error
}

func _JSONParse<A>(json: JSON) -> A? {
    return json as? A
}

func _JSONParse<A: JSONDecodable>(json: JSON) -> A? {
    return A.decode1(json)
}

extension String: JSONDecodable {
   static func decode1(json: JSON) -> String? {
        return json as? String
    }
}

extension Int: JSONDecodable {
    static func decode1(json: JSON) -> Int? {
        return json as? Int
    }
}

extension Double: JSONDecodable {
   static func decode1(json: JSON) -> Double? {
        return json as? Double
    }
}

extension Bool: JSONDecodable {
    static func decode1(json: JSON) -> Bool? {
        return json as? Bool
    }
}
func extract<A>(json: JSONDictionary, key: String) -> A? {
    return json[key] >>> _JSONParse
}

func extractPure<A>(json: JSONDictionary, key: String) -> A?? {
    return pure(json[key] >>> _JSONParse)
}

//-------- Operators for Pull data from JSON -------


infix operator <| { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> A? {
    return d[key] >>> _JSONParse
}

// Pull dictionary from JSON
func <|(d: JSONDictionary, key: String) -> JSONDictionary {
    return d[key] >>> _JSONParse ?? JSONDictionary()
}

// Pull array from JSON
func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

// Pull optional value from JSON
func <|*<A: JSONDecodable>(d: JSONDictionary, key: String) -> A?? {
    return pure(d <| key)
}

//~~~~~~~~~~~~~~~~ MODEL User ~~~~~~~~~~~~~~~~~~~~~~~~~~~

struct User: JSONDecodable, Printable {
    let id: Int
    let name: String
    let email: String?
    
    
    var description : String {
        return "User { id = \(id), name = \(name), email = \(email)}"
    }
    
    static func create(id: Int)(name: String)(email: String?) -> User {
        return User(id: id, name: name, email: email)
    }
    
//---------- Final version -------------
    
    static func decode1(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <|  "id"
                <*> d <|  "name"
                <*> d <|* "email"
        }
    }
/*
//---------- Version with extract -------------
    
    static func decode1(json: JSON) -> User? {

           return _JSONParse(json) >>> { d in
                User.create <^>
                    extract (d,"id")    <*>
                    extract (d,"name")  <*>
                    extractPure (d,"email")
            }
    }
*/
}

//~~~~~~~~~~~~~~~~~~ PARSING User~~~~~~~~~~~~~~~~~~~~~~~~~

func getUser5(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Wrong data for Parsing"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//      ----- Test 1 - Correct data -----------

getUser5(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тest 2 - incorrect data (extra curly brase) -----

getUser5(jsonData1){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Test 3 - incorrect data ( insread of "id" ve have "id1") -----

getUser5(jsonData2){ user in
    let a = stringResult(user)
    println("\(a)")
}
//      ----- Тest 4 - no email in JSON  -----------

getUser5(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
    return
}

