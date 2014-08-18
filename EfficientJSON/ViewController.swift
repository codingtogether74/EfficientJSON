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
        
        
//        getBlog0(jsonData)
/*
        getUser1(jsonData){ blog in
        println("\(blog)")
        }
        
        getBlog6(jsonData ){ result in
            switch result {
            case let .Error(err):
                println("Error")
            case let .Value(box):
                println("\(box.value)")
                
            }
        }
*/
        getBlog7(jsonData ){ result in
            for res: Result<Blog> in result {
                switch res {
                case let .Error(err):
                    println("Error: \(err)")
                case let .Value(box):
                    println("\(box.value)")}
                
            }
        }
//
    }
    
}