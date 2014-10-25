//
//  Place.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/15/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

struct Place: Printable ,JSONDecodable {
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

    static func decode1(json: JSON) -> Place? {  //--------------------decode1
        return  JSONObject(json) >>> { d in

            Place.create <^>
                d["place_url"] >>> JSONString <*>
                d["timezone"]  >>> JSONString <*>
                d["photo_count"] >>> JSONString <*>
                d["_content"] >>> JSONString
        }
    }
}
// ---- Конец структуры Place ----

// ----Структура Places ----

struct Places: Printable,JSONDecodable {
    
    var places : [Place]
    
    var description :String  { get {
        var str: String = ""
            for place in self.places {
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
    
    static func decode1(json: JSON) -> Places? {     //---------------decode1
        return create <*> JSONObject(json) >>> {
            dictionary ($0,"places") >>> {
                array($0, "place") >>> {
                    flatten($0.map(Place.decode1) )}}}   //-----------------decode1

    }
}
// ---- Конец структуры Places----

