EfficientJSON
=============

Follow article "Efficient JSON in Swift with Functional Concepts and Generic"
http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

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
