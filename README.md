<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
    <img src="https://img.shields.io/github/workflow/status/MihaelIsaev/Vaporizer/test" alt="Github Actions">
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
</p>

# Declarativity + Vapor

You could make your Vapor app look a little bit different ✈️

Let's start from your `Run` scheme with `main.swift` file

We could change it to this

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try app.setup(appBody).run()
```

Then let's switch to your `App` scheme where you have `configure.swift` and `routes.swift` files.

Let's rename `configure.swift` into `app.swift` which will look like this

```swift
import Vaporizer // it imports Vapor automatically

// Called before your application initializes.
@AppBuilder public var appBody: AppBuilder.Result {
    // here we could place some wrapped configuration (read below)
    ManualConfiguration { app in
        // here we could place everything from old `configure.swift`
        // but some parts could be rewritten declaratively (read below)
    }
    Routes {
        // here we could place our routes declaratively (read below as well)
    }
}
```

## Wrapped things

I've just started wrapping, so please join, pull requests are very welcome 😃

### Logger

```swift
@AppBuilder public var appBody: AppBuilder.Result {
    // ...
    Logger.level(.debug)
    // ...
}
```

### HTTPServer

```swift
@AppBuilder public var appBody: AppBuilder.Result {
    // ...
    HTTPServer.hostname(env: "SERVER_HOST").port(env: "SERVER_PORT") // will read environment variables
    // or
    HTTPServer.hostname("192.168.0.1").port(8585)
    // ...
}
```

### FileMiddleware

```swift
@AppBuilder public var appBody: AppBuilder.Result {
    // ...
    #if os(macOS) // don't use this middleware for production, please!
    FileMiddleware() // by default to public
    // or
    FileMiddleware.publicDirectory("CustomDir")
    #endif
    // ...
}
```

### CORSMiddleware

```swift
@AppBuilder public var appBody: AppBuilder.Result {
    // ...
    CORSMiddleware
        .allowedOrigin(.all)
        .allowedMethods(.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH)
        .allowedHeaders(.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin)
        .allowCredentials()
        .exposedHeaders(...)
        .cacheExpiration(...)
    // ...
}
```

### Routes

It is my most desired thing, I just love to see the whole API beautifully described

Ok, so let's start rewriting your `routes.swift`

We have two things in `RouteBuilder`
- groups
- middlewares

Let's say that you have `let v1 = app.grouped("v1")` route group which is not protected, we could rewrite it this easy way

```swift
Group("v1") {
    // subgroups or/and endpoints here
}
```

then maybe you have two more route groups inside `v1`, let's say `auth` which is obviously not protected and `profile` which is only for authorized users

```swift
Group("v1") {
    Group("auth") {
        // subgroups or/and endpoints here
    }
    Group("profile").protectedBy(AuthMiddleware()).routes {
        // subgroups or/and endpoints here
    }
}
```

Easy, right? 😜 Then let's move to endpoints declaration

With pure Vapor you may have endpoints for authorization declared this way

```swift
let v1 = app.grouped("v1")
let auth = v1.grouped("auth")
auth.post("signup") { req -> EventLoopFuture<HTTPStatus> in
    // ...
}
```

which could be easily rewritten this way

```swift
Group("v1") {
    Group("auth") {
        Post("signup") { req -> EventLoopFuture<HTTPStatus> in
            // ...
        }
    }
}
```

then for `profile` group

```swift
let profile = v1.grouped("profile").grouped(AuthMiddleware())
/// Gets current profile
profile.get(use: my) { req -> EventLoopFuture<UserProfile> in
    // ...
}
/// Updates profile info
profile.on(.PATCH, body: .collect(maxSize: .init(value: 1024 * 1024 * 20))) { req -> EventLoopFuture<HTTPStatus> in
    // ...
}
```

let's rewrite it into this

```swift
Group("v1") {
    Group("profile") {
        Get { req -> EventLoopFuture<UserProfile> in
            // ...
        }
        Patch(body: .collect(maxSize: .init(value: 1024 * 1024 * 20))) { req -> EventLoopFuture<HTTPStatus> in
            // ...
        }
    }
}
```

it looks good now, but I'm sure that you use some dedicated files for route groups (like route collections), so let's make it look better.
I propose you to create files something like this

`/Controllers/Auth/AuthController.swift`
```swift
struct AuthController {}
```
`/Controllers/Auth/Auth+Signup.swift`
```swift
extension AuthController {
    static func signup(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        // ...
    }
}
```
same for profile
`/Controllers/Profile/ProfileController.swift`
```swift
struct ProfileController {}
```
`/Controllers/Profile/Profile+Get.swift`
```swift
extension ProfileController {
    static func get(on req: Request) throws -> EventLoopFuture<UserProfile> {
        // ...
    }
}
```
`/Controllers/Profile/Profile+UpdatePhoto.swift`
```swift
extension ProfileController {
    static func updatePhoto(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        // ...
    }
}
```

#### And final result with that may look like this

```swift
@AppBuilder public var appBody: AppBuilder.Result {
    // ...
    Routes {
        Get { "Hello dear stranger 😄" }
        Group("v1") {
            Group("auth").routes(AuthController.self) {
                Post("signup", use: $0.signup)
            }
            Group("profile").protectedBy(AuthMiddleware()).routes(ProfileController.self) {
                Get(use: $0.get)
                Patch(body: .collect(maxSize: .init(value: 1024 * 1024 * 20)), use: $0.updatePhoto)
            }
        }
    }
}
```

Isn't it beautiful? 😊

#### Some additional information about routes

You could build paths the same as with pure vapor using `:something`, `*`, and `**` cause it is just directly wrapped.
