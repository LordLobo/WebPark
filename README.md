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




