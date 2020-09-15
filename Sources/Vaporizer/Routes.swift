//
//  Routes.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor
import NIO

public typealias Group = Routes.Group
public typealias Endpoint = Routes.Endpoint

fileprivate struct _RE: ResponseEncodable {
    func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        obj.encodeResponse(for: request)
    }
    
    let obj: ResponseEncodable
    
    init (_ obj: ResponseEncodable) {
        self.obj = obj
    }
}

public class Routes: AppBuilderContent {
    public var appBuilderContent: AppBuilder.Item { .routes(self) }
    
    let item: RoutesFactory.Item
    
    init () {
        item = .none
    }
    
    public init (@RoutesFactory block: RoutesFactory.Block) {
        item = block().routesFactoryContent
    }
    
    func execute(_ app: Application) {
        apply(app, item)
    }
    
    private func apply(_ builder: RoutesBuilder, _ item: RoutesFactory.Item) {
        switch item {
        case .none: break
        case .items(let items):
            items.forEach { apply(builder, $0) }
        case .endpoint(let endpoint):
            guard let endpoint = endpoint as? _AnyRoutesEndpoint else { break }
            let responder = BasicResponder { request in
                if case .collect(let max) = endpoint.bodyStrategy ?? .collect, request.body.data == nil {
                    return request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value)
                        .flatMapThrowing { _ -> _RE in
                            _RE(try endpoint.closure(request))
                        }.encodeResponse(for: request)
                } else {
                    return try endpoint.closure(request).encodeResponse(for: request)
                }
            }
            builder.add(Route(
                method: endpoint.method,
                path: endpoint.path,
                responder: responder,
                requestType: Request.self,
                responseType: Response.self
            ))
        case .group(let group):
            apply(builder.grouped(group.middlewares).grouped(group.path), group.routes.item)
        }
    }
}

extension Routes {
    public class Group: RoutesFactoryContent {
        public var routesFactoryContent: RoutesFactory.Item { .group(self) }
        
        let path: [PathComponent]
        var middlewares: [Middleware] = []
        var routes: Routes { _routes ?? Routes() }
        private var _routes: Routes?
        
        public init (_ path: [PathComponent]) {
            self.path = path
        }
        
        public init (_ path: PathComponent...) {
            self.path = path
        }
        
        public init (_ path: [PathComponent], protectedBy middlewares: [Middleware] = [], @RoutesFactory block: RoutesFactory.Block) {
            self.path = path
            self.middlewares = middlewares
            self._routes = .init(block: block)
        }
        
        public init (_ path: PathComponent..., protectedBy middlewares: [Middleware] = [], @RoutesFactory block: RoutesFactory.Block) {
            self.path = path
            self.middlewares = middlewares
            self._routes = .init(block: block)
        }
        
        public init<T>(_ path: [PathComponent], protectedBy middlewares: [Middleware] = [], controller: T.Type, @RoutesFactory block: (T.Type) -> RoutesFactory.Result) {
            self.path = path
            self.middlewares = middlewares
            self._routes = .init(block: {
                block(T.self)
            })
        }
        
        public init<T>(_ path: PathComponent..., protectedBy middlewares: [Middleware] = [], controller: T.Type, @RoutesFactory block: (T.Type) -> RoutesFactory.Result) {
            self.path = path
            self.middlewares = middlewares
            self._routes = .init(block: {
                block(T.self)
            })
        }
        
        public init (_ path: PathComponent..., protectBy middlewares: [Middleware] = [], routes: Routes) {
            self.path = path
            self.middlewares = middlewares
            self._routes = routes
        }
        
        public func protectedBy(_ middlewares: Middleware...) -> Self {
            protectedBy(middlewares)
        }
        
        public func protectedBy(_ middlewares: [Middleware]) -> Self {
            self.middlewares.append(contentsOf: middlewares)
            return self
        }
        
        public func routes(@RoutesFactory block: RoutesFactory.Block) -> Self {
            _routes = .init(block: block)
            return self
        }
        
        public func routes<T>(_ controller: T.Type, @RoutesFactory block: (T.Type) -> RoutesFactory.Result) -> Self {
            self._routes = .init(block: {
                block(T.self)
            })
            return self
        }
    }
}

public protocol AnyRoutesEndpoint {}

protocol _AnyRoutesEndpoint: AnyRoutesEndpoint {
    var method: HTTPMethod { get }
    var path: [PathComponent] { get }
    var bodyStrategy: HTTPBodyStreamStrategy? { get }
    var closure: (Request) throws -> ResponseEncodable { get }
}

extension Routes {
    public class Endpoint<Response>: _AnyRoutesEndpoint, RoutesFactoryContent where Response: ResponseEncodable {
        public var routesFactoryContent: RoutesFactory.Item { .endpoint(self) }
        
        var method: HTTPMethod
        var path: [PathComponent]
        var bodyStrategy: HTTPBodyStreamStrategy?
        var closure: (Request) throws -> ResponseEncodable
        
        init (_ method: HTTPMethod, path: [PathComponent], body: HTTPBodyStreamStrategy? = nil, use closure: @escaping (Request) throws -> Response) {
            self.method = method
            self.path = path
            self.bodyStrategy = body
            self.closure = closure
        }
        
        init (_ method: HTTPMethod, path: PathComponent..., body: HTTPBodyStreamStrategy? = nil, use closure: @escaping (Request) throws -> Response) {
            self.method = method
            self.path = path
            self.bodyStrategy = body
            self.closure = closure
        }
    }
}

public typealias Get = Routes.Get
public typealias Post = Routes.Post
public typealias Patch = Routes.Patch
public typealias Put = Routes.Put
public typealias Delete = Routes.Delete

extension Routes {
    public class SimpleEndpoint<Response>: RoutesFactoryContent where Response: ResponseEncodable {
        public var routesFactoryContent: RoutesFactory.Item { .endpoint(endpoint) }
        
        var endpoint: Endpoint<Response> { .init(.GET, path: path, use: closure) }
        var path: [PathComponent]
        var closure: (Request) throws -> Response
        
        public init (_ path: PathComponent..., use closure: @escaping () throws -> Response) {
            self.path = path
            self.closure = { _ in
                try closure()
            }
        }
        
        public init (_ path: [PathComponent], use closure: @escaping () throws -> Response) {
            self.path = path
            self.closure = { _ in
                try closure()
            }
        }
        
        public init (_ path: PathComponent..., use closure: @escaping (Request) throws -> Response) {
            self.path = path
            self.closure = closure
        }
        
        public init (_ path: [PathComponent], use closure: @escaping (Request) throws -> Response) {
            self.path = path
            self.closure = closure
        }
    }
    
    public class SimpleEndpointWithBody<Response>: SimpleEndpoint<Response> where Response: ResponseEncodable {
        var bodyStrategy: HTTPBodyStreamStrategy?
        
        public init (_ path: PathComponent..., body: HTTPBodyStreamStrategy = .collect, use closure: @escaping () throws -> Response) {
            self.bodyStrategy = body
            super.init(path, use: closure)
        }
        
        public init (_ path: [PathComponent], body: HTTPBodyStreamStrategy = .collect, use closure: @escaping () throws -> Response) {
            self.bodyStrategy = body
            super.init(path, use: closure)
        }
        
        public init (_ path: PathComponent..., body: HTTPBodyStreamStrategy = .collect, use closure: @escaping (Request) throws -> Response) {
            self.bodyStrategy = body
            super.init(path, use: closure)
        }
        
        public init (_ path: [PathComponent], body: HTTPBodyStreamStrategy = .collect, use closure: @escaping (Request) throws -> Response) {
            self.bodyStrategy = body
            super.init(path, use: closure)
        }
    }
    
    public class Get<Response>: SimpleEndpoint<Response> where Response: ResponseEncodable {}
    
    public class Post<Response>: SimpleEndpointWithBody<Response> where Response: ResponseEncodable {
        override var endpoint: Endpoint<Response> { .init(.POST, path: path, body: bodyStrategy, use: closure) }
    }
    
    public class Patch<Response>: SimpleEndpointWithBody<Response> where Response: ResponseEncodable {
        override var endpoint: Endpoint<Response> { .init(.PATCH, path: path, body: bodyStrategy, use: closure) }
    }
    
    public class Put<Response>: SimpleEndpointWithBody<Response> where Response: ResponseEncodable {
        override var endpoint: Endpoint<Response> { .init(.PUT, path: path, body: bodyStrategy, use: closure) }
    }
    
    public class Delete<Response>: SimpleEndpointWithBody<Response> where Response: ResponseEncodable {
        override var endpoint: Endpoint<Response> { .init(.DELETE, path: path, body: bodyStrategy, use: closure) }
    }
}
