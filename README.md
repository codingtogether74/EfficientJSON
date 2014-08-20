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

We need to restore the array of blogs.


I follow atrticle step by step and create some functions

getBlog0(...), getBlog1(...) and etc.

I take some ideas from "Parsing JSON in Swift"  by Chris Eidhof and final function looks like this

<pre>
func getBlog7(jsonOptional: NSData?, callback: ([Result<Blog>]) -> ()) {
    let json =   jsonOptional >>> decodeJSON  >>> JSONObject
    let blogs: ()? = dictionary(json!,"blogs") >>> {
                             array($0, "blog") >>> {join($0.map(Blog.decode))}
                                               >>> callback
    }
}
</pre>

and call this function like this

<pre>
        getBlog7(jsonData ){ result in
            for res: Result<Blog> in result {
                switch res {
                case let .Error(err):
                    println("Error: \(err)")
                case let .Value(box):
                    println("\(box.value)")}
                
            }
        }

</pre>

I use curried functions to initialize struct Blog.
