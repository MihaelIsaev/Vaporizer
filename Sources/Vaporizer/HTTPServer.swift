//
//  HTTPServer.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

public class HTTPServer: AppBuilderContent {
    public var appBuilderContent: AppBuilder.Item { .httpServer(self) }
    
    private init() {}
    
    private var hostname: String?
    private var port: Int?
    
    func _apply(_ app: Application) {
        if let v = hostname {
            app.http.server.configuration.hostname = v
        }
        if let v = port {
            app.http.server.configuration.port = v
        }
    }
    
    public func hostname(_ v: String) -> Self {
        hostname = v
        return self
    }
    
    public func hostname(env key: String) -> Self {
        hostname = Environment.get(key)
        return self
    }
    
    public func port(_ v: Int) -> Self {
        port = v
        return self
    }
    
    public func port(_ v: String) -> Self {
        port = Int(v)
        return self
    }
    
    public func port(env key: String) -> Self {
        if let v = Environment.get(key) {
            port = Int(v)
        }
        return self
    }
    
    public static func hostname(_ v: String) -> HTTPServer {
        HTTPServer().hostname(v)
    }
    
    public static func hostname(env key: String) -> HTTPServer {
        HTTPServer().hostname(env: key)
    }
    
    public static func port(_ v: Int) -> HTTPServer {
        HTTPServer().port(v)
    }
    
    public static func port(_ v: String) -> HTTPServer {
        HTTPServer().port(v)
    }
    
    public static func port(env key: String) -> HTTPServer {
        HTTPServer().port(env: key)
    }
}
