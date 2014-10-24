// Playground - noun: a place where people can play
import Foundation

//---- по статье http://robots.thoughtbot.com/real-world-json-parsing-with-swift

/*  

Все компоненты присутствуют

let parsedJSON : [String:AnyObject] = [
"id": 1,
"name": "Cool User",
"email": "u.cool@example.com"
] 

ИЛИ

Отсутствует компонент email

let parsedJSON1 : [String:AnyObject] = [
"id": 1,
"name": "Cool User"
]
*/
//------- Исходные правильные данные для парсинга User -----
//      ----- Тест 1 - правильные данные  -----

let jsonString: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

let jsonString1: String = "{ {\"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData1: NSData? = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//      ----- Тест 3 - неправильные данные ( вместо "id" "id1") -----

let jsonString2: String = "{ \"id1\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData2: NSData? = jsonString2.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//      ----- Тест 4 - неправильные данные (отсутствует  email) -----

let jsonString3: String =  "{ \"id\": 1, \"name\":\"Cool user\" }"


let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)


//~~~~~~~~~~~~~~~~~~~~~~~ ПАРСИНГ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>


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

//--------------- Для печати Result ---


 func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
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
func extract<A>(json: JSONDictionary, key: String) -> A? {
    return json[key] >>> _JSONParse
}

func extractPure<A>(json: JSONDictionary, key: String) -> A?? {
    return pure(json[key] >>> _JSONParse)
}
///-------- Операторы извлечения данных из JSON-------

infix operator <| { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> A? {
    return d[key] >>> _JSONParse
}

func <|(d: JSONDictionary, key: String) -> JSONDictionary {
    return d[key] >>> _JSONParse ?? JSONDictionary()
}

func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

func <|*<A: JSONDecodable>(d: JSONDictionary, key: String) -> A?? {
    return pure(d <| key)
}
//~~~~~~~~~~~~~~~~ МОДЕЛЬ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
    
//---------- ОКОНЧАТЕЛЬНЫЙ ВАРИАНТ -------------
    
    static func decode1(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <|  "id"
                <*> d <|  "name"
                <*> d <|* "email"
        }
    }
/*
//---------- ВАРИАНТ с extract -------------
    
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

//~~~~~~~~~~~~~~~~~~ User ПАРСИНГ~~~~~~~~~~~~~~~~~~~~~~~~~

func getUser5(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//      ----- Тест 1 - правильные данные -----

getUser5(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

getUser5(jsonData1){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 3 - неправильные данные ( вместо "id" "id1") -----

getUser5(jsonData2){ user in
    let a = stringResult(user)
    println("\(a)")
}
//      ----- Тест 4 - отсутствует email в JSON данных -----

getUser5(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
    return
}

