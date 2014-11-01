// Playground - noun: a place where people can play

import Foundation

//---- по статье http://robots.thoughtbot.com/parsing-embedded-json-and-arrays-in-swift

// ----- IT COULD TAKE MINUTES to Build ---- WAIT -----

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
//----------------------------- from Optional to  Result<A> ---------

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
    
    return resultFromOptional(jsonOptional, NSError(localizedDescription: "JSON данные неверны")) // use the error from NSJSONSerialization or a custom error message
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

func <|(d: JSONObject, key: String) -> JSONObject {
    return d[key] >>> _JSONParse ?? JSONObject()
}

func <|<A: JSONDecodable>(d: JSONObject, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

func <|*<A: JSONDecodable>(d: JSONObject, key: String) -> A?? {
    return pure(d <| key)
}

//~~~~~~~~~~~~~~~~ MODEL Post ~~~~~~~~~~~~~~~~~~~~~~~~~~~
struct Post: JSONDecodable, Printable {
    let id: Int
    let text: String
    let authorName: String
    
    
    var description : String {
        return "Post { id = \(id), text = \(text), authorName = \(authorName)}"
    }
    
    static func create(id: Int)(text: String)(authorName: String) -> Post {
        return Post(id: id, text: text, authorName: authorName)
    }
    
    
    static func decode1(json: JSON) -> Post? {
        return _JSONParse(json) >>> { d in
            Post.create
                <^> d <|  "id"
                <*> d <|  "text"
                <*> d <|  "author" <| "name"
        }
    }
}

//~~~~~~~~~~~~~~~~~~ PARSING Post ~~~~~~~~~~~~~~~~~~~~~~~~~

func getPost(jsonOptional: NSData?, callback: (Result<Post>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//----------------- Test 1 - Correct data -----

getPost(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}
/*
//--------------- Comment ------
let parsedJSON1 : [String:AnyObject] =
{
"id": 6,
"text": "Cool story bro.",
"author": {
            "id": 1,
            "name": "Cool User"
          }
}
*/
//~~~~~~~~~~~~~~~~ МОДЕЛЬ Comment ~~~~~~~~~~~~~~~~~~~~~~~~~~~

struct Comment: JSONDecodable, Printable {
    let id: Int
    let text: String
    let authorName: String
    
    
    var description : String {
        return "Comment { id = \(id), text = \(text), authorName = \(authorName)}"
    }
    
    static func create(id: Int)(text: String)(authorName: String) -> Comment {
        return Comment(id: id, text: text, authorName: authorName)
    }
    
    
    static func decode1(json: JSON) -> Comment? {
        return _JSONParse(json) >>> { d in
            Comment.create
                <^> d <|  "id"
                <*> d <|  "text"
                <*> d <|  "author" <| "name"
        }
    }
}
//~~~~~~~~~~~~~~~~~~ PARSING Comment ~~~~~~~~~~~~~~~~~~~~~~~~~

func getComment(jsonOptional: NSData?, callback: (Result<Comment>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//----------------- Test 1 - Correct data -----

getComment(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}
//--------------- User ------------------

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
    
    static func decode1(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <|  "id"
                <*> d <|  "name"
                <*> d <|* "email"

        }
    }
}
//-------------- DATA ----------------------

//let jsonString3: String =  "{ \"id\": 1, \"name\":\"Cool user\" }"
let jsonString3: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//------------ Test User -----

func getUser(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getUser(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ MODEL Post1 with Comments ~~~~~~~~~~~~~~~~~~~~~~~~~~~

//-------------------- DATA -------------
let jsonString5: String = "{\"id\": 3, \"text\": \"A Cool story.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"},\"comments\": [{\"id\": 6,\"text\": \"Cool story bro.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"}},{\"id\": 6,\"text\": \"Cool story bro.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"}}]}"

let jsonData5: NSData? = jsonString5.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//--------------- Post1 ------------------

struct Post1: JSONDecodable, Printable {
    let id: Int
    let text: String
    let author: User
    
    var description : String {
        return "Post1 { id = \(id), text = \(text), author = \(author.description)}"
    }
    
    
    
    static func create(id: Int)(text: String)(author: User)-> Post1 {
        return Post1(id: id, text: text, author: author)
    }
    
    static func decode1(json: JSON) -> Post1? {
        return _JSONParse(json) >>> { d in
            Post1.create
                <^> d <| "id"
                <*> d <| "text"
                <*> d <| "author"
        }
    }
}
//------------ Test Post1 -----

func getPost1(jsonOptional: NSData?, callback: (Result<Post1>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Wrong data for parsing"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getPost1(jsonData5){ user in
    let a = stringResult(user)
    println("\(a)")
}
/* ---------- Post2 with Comments -------------------
let parsedJSON : [String:AnyObject] =
{
    "id": 3,
    "text": "A Cool story.",
    "author": {
                "id": 1,
                "name": "Cool User"
               },
    "comments": [
                  {
                    "id": 6,
                    "text": "Cool story bro.",
                    "author": {
                                "id": 1,
                                "name": "Cool User"
                               }
                  },
                 {
                    "id": 6,
                    "text": "Cool story bro.",
                    "author": {
                                "id": 1,
                                "name": "Cool User"
                              }
                 }
                ]
}
*/
//~~~~~~~~~~~~~~~ Post2 ~~~~~~~~~~~~~~~~~~~

struct Post2: JSONDecodable, Printable {
    let id: Int
    let text: String
    let author: User
    let comments: [Comment]


    var description : String {
        var str: String = ""
        for comment in self.comments {
            str = str +  "\(comment.description) \n"
        }
        return "Post2 { id = \(id), text = \(text), author = \(author.description)}" + str
    }
    
    
    
    static func create(id: Int)(text: String)(author: User)(comments: [Comment]) -> Post2 {
        return Post2(id: id, text: text, author: author, comments: comments)
    }
    
    static func decode1(json: JSON) -> Post2? {
        return _JSONParse(json) >>> { d in
            Post2.create
                <^> d <| "id"
                <*> d <| "text"
                <*> d <| "author"
                <*> d <| "comments"
        }
    }
}
//------------ Тест Post1 -----

func getPost2(jsonOptional: NSData?, callback: (Result<Post2>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Wrong data for parsing"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getPost2(jsonData5){ user in
    let a = stringResult(user)
    println("\(a)")
}

