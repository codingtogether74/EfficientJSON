// Playground - noun: a place where people can play
import Foundation
struct Blog: Printable {
    let id: Int
    let name: String
    let needsPassword : Bool
    let url: NSURL
    var description : String {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
    }
}
var jsonString1 = "{ \"stat\": \"ok\", \"blogs\": { \"blog\": [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ] } }"
let jsonData1 = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

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
                                            let blog = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url))
                                            callback(blog)
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
getBlog1(jsonData1){ blog in
    println("\(blog.description)")
}

//=======
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


// ------------ Возврат ошибки NSError ----
// Для упрощения работы с классом NSError создаем "удобный" инициализатор в расширении класса

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
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

//--------------------- Новые операторы <^>   и  <*>  ---

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
func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}

func decodeJSON(data: NSData) -> Result<JSON> {
    let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
    return resultFromOptional(jsonOptional, NSError(localizedDescription: "исходные данные неверны")) // use the error from NSJSONSerialization or a custom error message
}


//--------------------- Оператор >>> для Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}
//========================== Используем Generic =====

protocol JSONDecodable {
    class func decode(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode(json), NSError(localizedDescription: "Отсутствуют компоненты User1")) // custom error
}
//-----------------------------------------
struct Response {
    let data: NSData
    let statusCode: Int = 500
    
    init(data: NSData, urlResponse: NSURLResponse) {
        self.data = data
        if let httpResponse = urlResponse as? NSHTTPURLResponse {
            statusCode = httpResponse.statusCode
        }
    }
}

func performRequest(request: NSURLRequest, callback: (Result<NSData>) -> ()) {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, urlResponse, error in
        println("\(error.localizedDescription)")
        callback(parseResult(data, urlResponse, error))
    }
    task.resume()
}

func parseResult(data: NSData!, urlResponse: NSURLResponse!, error: NSError!) -> Result<NSData> {
    println("\(error.localizedDescription)")
    let responseResult: Result<Response> = Result(error, Response(data: data, urlResponse: urlResponse))
    return responseResult >>> parseResponse

}

func parseResponse(response: Response) -> Result<NSData> {
    let successRange = 200..<300
    if !contains(successRange, response.statusCode) {
        return .Error(NSError()) // customize the error message to your liking
    }
    return Result(nil, response.data)
}
//==============
struct Place: JSONDecodable, Printable {
    let placeURL: String
    let timeZone: String
    let photoCount : String
    let content : String
    
    
    var description : String {
        return "Place { placeURL = \(placeURL), timeZone = \(timeZone), photoCount = \(photoCount),content = \(content)} \n"
    }
        
    static func create(placeURL: String)(timeZone: String)(photoCount: String)(content: String) -> Place {
        return Place(placeURL: placeURL, timeZone: timeZone, photoCount: photoCount,content: content)
    }
    
    static func stringResult(result: Result<Place> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }

    static func decode(json: JSON) -> Place? {
        return JSONObject(json) >>> { d in
            Place.create <^>
                json["place_url"] >>> JSONString <*>
                json["timezone"]  >>> JSONString <*>
                json["photo_count"] >>> JSONString <*>
                json["_content"] >>> JSONString
        }
    }

}
//----------------------
func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)
}

let urlPlaces  = NSURLRequest( URL: toURL( "https://api.flickr.com/services/rest/?method=flickr.places.getTopPlacesList&place_type_id=7&format=json&nojsoncallback=1&api_key=2d57c18bb70d5b3aea7b3b0034567af1"))
 

