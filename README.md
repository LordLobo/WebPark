# WebPark

REST that is a walk in the park!

Using generics and Swift Concurrancy, WebPark provides a simple set of HTTP interactions with a minimal API.

## Usage

Extend the `WebPark` protocol and add a `baseURL`. Optionally add a JWT Token:

```
struct myREST : WebPark {
    let baseURL = "https://google.com"
    let token = "myJWT"
}
```

Then create the codable object you're expecting:

```
struct MyData : Codable {
    let name: String
}
```

Then add a method for an endpoint:

```
extention myREST {
    func getMyData() async throws -> MyData {
        return await get("/endpointForMyData")
    }
}
```

License (MIT):

Copyright 2022 Dan Giralté

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



