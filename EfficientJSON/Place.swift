//
//  Place.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/15/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation
struct Place: Printable {
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
    
    static func decode1(json: JSON) -> Place? {
        return  JSONObject(json) >>> { d in

            Place.create <^>
                json["place_url"] >>> JSONString <*>
                json["timezone"]  >>> JSONString <*>
                json["photo_count"] >>> JSONString <*>
                json["_content"] >>> JSONString
        }
    }
}
// ---- Конец структуры Place ----

    func decodeObjectPlaces(json: JSON) -> [Place]? {
    return  json  >>> JSONObject >>> {
        dictionary ($0,"places") >>> {
            array($0, "place") >>> {
                join($0.map(Place.decode1) )}}}
}

func decodeResultPlaces(json: JSON) -> Result<[Place]> {
    let places:[Place]? = decodeObjectPlaces(json)
     return resultFromOptional(places, NSError()) // custom error message
}

// ----Структура Places ----

struct Places: Printable,JSONDecodable {
    
    var places : [Place]?
    var description :String  { get {
        var str: String = ""
            for place in self.places! {
             str = str +  "\(place) \n"
            }
          return str
        }
    }
    
    init(places1: [Place]){
       self.places = places1
    }
    static func create(places: [Place]) -> Places {
        return Places(places1: places)
    }
    
    static func decode1(json: JSON) -> Places? {
        return create <*> JSONObject(json) >>> {
            dictionary ($0,"places") >>> {
                array($0, "place") >>> {
                    join($0.map(Place.decode1) )}}}

    }
    
    static func stringResult(result: Result<Places> ) -> String {
        switch result {
        case let .Error(err):
            return "\(err.localizedDescription)"
        case let .Value(box):
            return "\(box.value.description)"
        }
    }
}
// ---- Конец структуры Places----

