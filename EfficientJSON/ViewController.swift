//
//  ViewController.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 8/7/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Do any additional setup after loading the view, typically from a nib.
        var jsonString = "{ \"stat\": \"ok\", \"blogs\": { \"blog\": [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ] } }"
        let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
//----------------------------------------------------
        let jsonString1 = "{  \"id\": 1, \"name\" : \"Cool user\",  \"email\" : \"u.cool@example.com\" }"

        
        let jsonData1: NSData? = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//---------------------------------------------------------
//        getBlog0(jsonData)

        let urlPlaces  = NSURLRequest( URL: toURL( "https://api.flickr.com/services/rest/?method=flickr.places.getTopPlacesList&place_type_id=7&format=json&nojsoncallback=1&api_key=2d57c18bb70d5b3aea7b3b0034567af1"))
//        performRequest(urlPlaces ) { places in
//                        println("\(Places.stringResult(places))")
//        }

        getUser0(jsonData1){ user in
                println("\(user)")
                
        }
        
        getUser4(jsonData1 ){ user in
             println("\(User.stringResult(user))")
        }
        //      ----- Тест 1 - правильные данные -----
        
        getUser5(jsonData1){ user1 in
            let a = User1.stringResult(user1)
            println("\(a)")
        }

/*
        getBlog1(jsonData){ blog in
            println("\(blog)")
        }

*/
//
/*
        getBlog6(jsonData ){ result in
            switch result {
            case let .Error(err):
                println("Error")
            case let .Value(box):
                println("\(box.value)")
                
            }
        }
*/
//
        getBlog10(jsonData ){ result in
            for res: Result<Blog> in result {
                switch res {
                case let .Error(err):
                    println("Error: \(err)")
                case let .Value(box):
                    println("\(box.value)")}
                
            }
        }
        getBlog11(jsonData ) { blogs in
            println("БЛОГИ: \(Blogs.stringResult(blogs))")
        }

//
        
    }
    
}