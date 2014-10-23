// Playground - noun: a place where people can play

import Foundation

//---- по статье http://robots.thoughtbot.com/parsing-embedded-json-and-arrays-in-swift

/*  структура Post поста социальных сетей

let parsedJSON : [String:AnyObject] =
{
"id": 5,
"text": "This is a post.",
"author": {
            "id": 1,
            "name": "Cool User"
}
}*/

//------- Исходные правильные данные для парсинга Post -----
//      ----- Тест 1 - правильные данные  -----

let jsonString: String = "{ \"id\": 5, \"text\":\"This is a post.\",  \"author\": { \"id\": 5, \"name\":\"Cool User\" }}"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~~~~~~~~~ ПАРСИНГ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONObject = [String:JSON]
typealias JSONArray = [JSON]


//---------- ОПЕРАТОРЫ функционального программирования >>>  <^>   и  <*>  ---
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

//~~~~~~~~~~ работаем с enum  Result<A> ~~~~~~~~~~~~

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
//-----------------------------от Optional к  Result<A> ---------

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}
// ------------ Возврат ошибки NSError ----
// Для упрощения работы с классом NSError создаем "удобный" инициализатор в расширении класса

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
//------------------ Для Result<JSON> -----

func decodeJSON(data: NSData) -> Result<JSON> {
    let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
    
    return resultFromOptional(jsonOptional, NSError(localizedDescription: "JSON данные неверны")) // use the error from NSJSONSerialization or a custom error message
}

//------------------ Для Optionals JSON? -----

func decodeJSON(data: NSData?) -> JSON? {
    var jsonErrorOptional: NSError?
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    if let json: JSON = jsonOptional {
        return json
    } else {
        return .None
    }
}
//--------------------- Оператор >>> для Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}
//~~~~~~~~~ДОБАВЛЯЕМ ФУНКЦИИ  ~~~~~~~~~~~~~~~~~~~
//------- flatten функцию ---
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
//---------------- Используем Generics -----------

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

//-------- Операторы извлечения данных из JSON-------

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

//~~~~~~~~~~~~~~~~ МОДЕЛЬ Post ~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
//---   Функция для печати на Playground ----
    
    static func stringResult(result: Result<Post> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}

//~~~~~~~~~~~~~~~~~~ ПАРСИНГ структуры Post~~~~~~~~~~~~~~~~~~~~~~~~~

func getPost(jsonOptional: NSData?, callback: (Result<Post>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
//      ----- Тест 1 - правильные данные -----

getPost(jsonData){ user in
    let a = Post.stringResult(user)
    println("\(a)")
}
/* ---------- Post c Comments -------------------
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
//---   Функция для печати на Playground ----
    
    static func stringResult(result: Result<Comment> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}
//~~~~~~~~~~~~~~~~~~ ПАРСИНГ структуры Comment~~~~~~~~~~~~~~~~~~~~~~~~~

func getComment(jsonOptional: NSData?, callback: (Result<Comment>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
//      ----- Тест 1 - правильные данные -----

getComment(jsonData){ user in
    let a = Comment.stringResult(user)
    println("\(a)")
}
//--------------- User ------------------
struct User: JSONDecodable {
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
    //---   Функция для печати на Playground ----
    
    static func stringResult(result: Result<User> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}
//  -------------- ДАННЫЕ ----------------------

//let jsonString3: String =  "{ \"id\": 1, \"name\":\"Cool user\" }"
let jsonString3: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//      ----- Тест User -----

func getUser(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getUser(jsonData3){ user in
    let a = User.stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ МОДЕЛЬ Post1 с Comments ~~~~~~~~~~~~~~~~~~~~~~~~~~~

//      -----------------ДАННЫЕ-------------
let jsonString5: String = "{\"id\": 3, \"text\": \"A Cool story.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"},\"comments\": [{\"id\": 6,\"text\": \"Cool story bro.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"}},{\"id\": 6,\"text\": \"Cool story bro.\",\"author\": {\"id\": 1,\"name\": \"Cool User\"}}]}"

let jsonData5: NSData? = jsonString5.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//--------------- Post1 ------------------

struct Post1: JSONDecodable {
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
//---   Функция для печати на Playground ----
    
    static func stringResult(result: Result<Post1> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}
//------------ Тест Post1 -----

func getPost1(jsonOptional: NSData?, callback: (Result<Post1>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}
getPost1(jsonData5){ user in
    let a = Post1.stringResult(user)
    println("\(a)")
}

