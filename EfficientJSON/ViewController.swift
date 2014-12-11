//
//  ViewController.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 8/7/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//
//---- Aticle http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

import UIKit

class ViewController: UITableViewController {

    var places :[Place]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//--------------- URL for places from Flickr.com ------------------------------------------

        let urlPlaces  = NSURLRequest( URL: FlickrFetcher.URLforTopPlaces())

        performRequest(urlPlaces ) { (places: Result<Places>) in
            switch places {
            case let .Error(err):
                println ("\(err.localizedDescription)")
            case let .Value(pls):
                self.places = pls.value.places

            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.tableView.reloadData()
                self.testUserAndBlogs()
                
            }
        }
        
    }
    
    // MARK: - TableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellIdentifier = "PlaceCell"
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = self.places![indexPath.row].content
        cell.detailTextLabel!.text = "\(self.places![indexPath.row].photoCount)"
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.places?.count ?? 0
    }
    
    // MARK: - testUserAndBlogs()

    func testUserAndBlogs() {
        //--------- Data for Blogs -------------------
        
        var jsonString = "{ \"stat\": \"ok\", \"blogs\": { \"blog\": [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ] } }"
        let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        //--------- Data for User with email -------------------
        
        let jsonString1 = "{  \"id\": 1, \"name\" : \"Cool user\",  \"email\" : \"u.cool@example.com\" }"
        let jsonData1: NSData? = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        //--------- Data for User without email -------------------
        
        let jsonString2 = "{  \"id\": 1, \"name\" : \"Cool user\" }"
        let jsonData2: NSData? = jsonString2.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        getUser4(jsonData1 ){ user in
            println("\(stringResult(user))")
        }
        //      ----- Тест 1 User1- правильные данные -----
        
        getUser5(jsonData1){ user1 in
            let a = stringResult(user1)
            println("------ 4--\(a)")
        }
        //      ----- Тест 1 User - правильные данные -----
        
        getUser6(jsonData2){ user in
            let a = stringResult(user)
            println("User6 ---\(a)")
        }
        
        
        getBlog1(jsonData){ blog in
            println("\(blog)")
        }
        
        getBlog6(jsonData ){ blog in
            println("----GetBlog6: \(stringResult(blog))")
        }
        
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
            println("BLOGS: \(stringResult(blogs))")
        }
    }
    
}