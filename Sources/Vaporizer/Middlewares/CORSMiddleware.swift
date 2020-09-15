//
//  CORSMiddleware.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

extension CORSMiddleware: AppBuilderContent {
    public var appBuilderContent: AppBuilder.Item { .middleware(self) }
    
    public class Declarative: AppBuilderContent {
        public var appBuilderContent: AppBuilder.Item {
            let config = CORSMiddleware.Configuration(
                allowedOrigin: _allowedOrigin,
                allowedMethods: _allowedMethods,
                allowedHeaders: _allowedHeaders,
                allowCredentials: _allowCredentials,
                cacheExpiration: _cacheExpiration,
                exposedHeaders: _exposedHeaders
            )
            return .middleware(CORSMiddleware(configuration: config))
        }
        
        private var _allowedOrigin: AllowOriginSetting = .originBased
        private var _allowedMethods: [HTTPMethod] = [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH]
        private var _allowedHeaders: [HTTPHeaders.Name] = [.accept, .authorization, .contentType, .origin, .xRequestedWith]
        private var _allowCredentials: Bool = false
        private var _cacheExpiration: Int = 600
        private var _exposedHeaders: [HTTPHeaders.Name]?
        
        public init () {}
        
        /// Setting that controls which origin values are allowed.
        public func allowedOrigin(_ v: AllowOriginSetting) -> Self {
            _allowedOrigin = v
            return self
        }
        
        /// Header string containing methods that are allowed for a CORS request response.
        public func allowedMethods(_ v: HTTPMethod...) -> Self {
            allowedMethods(v)
        }
        
        /// Header string containing methods that are allowed for a CORS request response.
        public func allowedMethods(_ v: [HTTPMethod]) -> Self {
            _allowedMethods = v
            return self
        }
        
        /// If set to yes, cookies and other credentials will be sent in the response for CORS request.
        public func allowCredentials(_ v: Bool = true) -> Self {
            _allowCredentials = v
            return self
        }
        
        /// Header string containing headers that are allowed in a response for CORS request.
        public func allowedHeaders(_ v: HTTPHeaders.Name...) -> Self {
            allowedHeaders(v)
        }
        
        /// Header string containing headers that are allowed in a response for CORS request.
        public func allowedHeaders(_ v: [HTTPHeaders.Name]) -> Self {
            _allowedHeaders = v
            return self
        }
        
        /// Optionally sets expiration of the cached pre-flight request. Value is in seconds.
        public func cacheExpiration(_ v: Int) -> Self {
            _cacheExpiration = v
            return self
        }
        
        /// Headers exposed in the response of pre-flight request.
        public func exposedHeaders(_ v: HTTPHeaders.Name...) -> Self {
            exposedHeaders(v)
        }
        
        /// Headers exposed in the response of pre-flight request.
        public func exposedHeaders(_ v: [HTTPHeaders.Name]) -> Self {
            _exposedHeaders = v
            return self
        }
    }
    
    /// Setting that controls which origin values are allowed.
    public static func allowedOrigin(_ v: AllowOriginSetting) -> Declarative {
        Declarative().allowedOrigin(v)
    }
    
    /// Header string containing methods that are allowed for a CORS request response.
    public static func allowedMethods(_ v: HTTPMethod...) -> Declarative {
        allowedMethods(v)
    }
    
    /// Header string containing methods that are allowed for a CORS request response.
    public static func allowedMethods(_ v: [HTTPMethod]) -> Declarative {
        Declarative().allowedMethods(v)
    }
    
    /// If set to yes, cookies and other credentials will be sent in the response for CORS request.
    public static func allowCredentials(_ v: Bool = true) -> Declarative {
        Declarative().allowCredentials(v)
    }
    
    /// Header string containing headers that are allowed in a response for CORS request.
    public static func allowedHeaders(_ v: HTTPHeaders.Name...) -> Declarative {
        allowedHeaders(v)
    }
    
    /// Header string containing headers that are allowed in a response for CORS request.
    public static func allowedHeaders(_ v: [HTTPHeaders.Name]) -> Declarative {
        Declarative().allowedHeaders(v)
    }
    
    /// Optionally sets expiration of the cached pre-flight request. Value is in seconds.
    public static func cacheExpiration(_ v: Int) -> Declarative {
        Declarative().cacheExpiration(v)
    }
    
    /// Headers exposed in the response of pre-flight request.
    public static func exposedHeaders(_ v: HTTPHeaders.Name...) -> Declarative {
        exposedHeaders(v)
    }
    
    /// Headers exposed in the response of pre-flight request.
    public static func exposedHeaders(_ v: [HTTPHeaders.Name]) -> Declarative {
        Declarative().exposedHeaders(v)
    }
}
