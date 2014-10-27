// Playground - noun: a place where people can play

import Foundation

//---- Article  http://robots.thoughtbot.com/parsing-embedded-json-and-arrays-in-swift

/*   Post to a social network

let parsedJSON : [String:AnyObject] =
{
"id": 5,
"text": "This is a post.",
"author": {
"id": 1,
"name": "Cool User"
}
}*/

//------- Correct data for parsing Post -----
//      ----- Test 1 - Correct data  -----

let jsonString: String = "{ \"id\": 5, \"text\":\"This is a post.\",  \"author\": { \"id\": 5, \"name\":\"Cool User\" }}"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~~~~~~~~~ PARSING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONObject = [String:JSON]
typealias JSONArray = [JSON]


//---------- Functional programming OPERATORS >>>  <^>   и  <*>  ---

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

//~~~~~~~~~~  enum  Result<A> ~~~~~~~~~~~~

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
    
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(Box(value))
        }
    }
}

//--------------- for Result print ---

func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}
//-----------------------------from Optional to  Result<A> ---------

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
    
    return resultFromOptional(jsonOptional, NSError(localizedDescription: "wrong JSON data")) // use the error from NSJSONSerialization or a custom error message
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
//--------------------- Operator >>> для Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
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

//-------pure function ---
func pure<A>(a: A) -> A? {
    return .Some(a)
}
//---------------- Use Generics -----------

protocol JSONDecodable {
    class func decode1(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode1(json), NSError(localizedDescription: "Отсутствуют компоненты модели")) // custom error
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

//-------- Operators for Pull data from JSON -------

infix operator <| { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

func <|<A: JSONDecodable>(d: JSONObject, key: String) -> A? {
    return d[key] >>> _JSONParse
}

// Pull dictionary from JSON
func <|(d: JSONObject, key: String) -> JSONObject {
    return d[key] >>> _JSONParse ?? JSONObject()
}

// Pull array from JSON
func <|<A: JSONDecodable>(d: JSONObject, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

// Pull optional value from JSON
func <|*<A: JSONDecodable>(d: JSONObject, key: String) -> A?? {
    return pure(d <| key)
}

//~~~~~~~~~~~~ BLOGS ~~~~~~~~~~~~~~~~~~
// Данные как в статье Chris Eidnof http://chris.eidhof.nl/posts/json-parsing-in-swift.html

/*
let parsedJSON : [String:AnyObject] = [
"stat": "ok",
"blogs": [
"blog": [
[
"id" : 73,
"name" : "Bloxus test",
"needspassword" : true,
"url" : "http://remote.bloxus.com/"
],
[
"id" : 74,
"name" : "Manila Test",
"needspassword" : false,
"url" : "http://flickrtest1.userland.com/"
]
]
]
]
*/
//~~~~~~~~~~~~~~~~~~~~~ Correct Data ~~~~~~~~~~~~~~~~~~~~~~~

var jsonString1 = "{ \"stat\": \"ok\", \"blogs\":  [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ]  }"
let jsonData1 = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~~~~~~~~~  MODEL Blog ~~~~~~~~~~~

//---------------------- String --> NSURL--------
func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)!
}
// ---------------------- Structure Blog ---------

struct Blog: Printable,JSONDecodable  {
    let id: Int
    let name: String
    let needsPassword : Int
    let url: NSURL
    
    var description : String { get {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
        }}
    
    static func create(id: Int)(name: String)(needsPassword: Int)(url:String) -> Blog {
        return Blog(id: id, name: name, needsPassword: needsPassword, url: toURL(url))
    }
    
    
    static func decode1(json: JSON) -> Blog? {
        return _JSONParse(json) >>> { d in
            Blog.create
                <^> d <| "id"
                <*> d <| "name"
                <*> d <| "needspassword"
                <*> d <| "url"
        }
    }
}

//-------------------- MODEL Blogs --------
// ------------------ Structure Blogs -----------

struct Blogs: Printable,JSONDecodable {
    
    var blogs : [Blog]
    
    var description :String  { get {
        var str: String = "Blogs :"
        for blog in self.blogs {
            str = str +  "\(blog.description) \n"
        }
        return str
        }
    }
    
    static func create(blogs: [Blog]) -> Blogs {
        return Blogs(blogs: blogs)
    }
    
    static func decode1(json: JSON) -> Blogs? {
        return _JSONParse(json) >>> { d in
            Blogs.create
                <^> d <| "blogs"

        }
    }
}

//------------ Test Blogs -----

func getBlogs(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Wrong data for parsing"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getBlogs(jsonData1){ user in
    let a = stringResult(user)
    println("\(a)")
}
