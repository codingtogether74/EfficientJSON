EfficientJSON
=============

Follow article "Efficient JSON in Swift with Functional Concepts and Generic"
http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

"Real World JSON Parsing with Swift"
http://robots.thoughtbot.com/real-world-json-parsing-with-swift

"Parsing Embedded JSON and Arrays in Swift"
http://robots.thoughtbot.com/parsing-embedded-json-and-arrays-in-swift

I took more complex example JSON from articles "Parsing JSON in Swift"  by Chris Eidhof
http://chris.eidhof.nl/posts/json-parsing-in-swift.html

and 

"JSON Parsing Reborn" David Owens 
http://owensd.io/2014/06/21/json-parsing-take-two.html

<pre>
var json : [String: AnyObject] = [
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
</pre>

We need to restore from JSON the array of MODELS blogs.


I follow atrticle step by step and create some functions

getBlog0(...), getBlog1(...) and etc.

I take some ideas from "Parsing JSON in Swift"  by Chris Eidhof and final function looks like this

<pre>
func getBlog(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: "  Wrong data for Parsing"))
let json: ()? =  jsonResult  >>> decodeJSON  >>> decodeObject >>> callback
}

</pre>

and call this function like this

<pre>
getBlog11(jsonData ) { blogs in
println("BLOGS: \(stringResult(blogs))")
}

</pre>

I use curried functions to wrap init struct Blog.
I tested ideas from aticles on data of Top Places from Flickr.com.
To get data from Flickr.com I use Flickr API from Stanford CS193P course. It was written in Objective-C, 
so I had to use Objective-C classes in Swift.
