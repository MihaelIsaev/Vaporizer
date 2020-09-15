//
//  AppBuilder.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

public protocol AppBuilderContent {
    var appBuilderContent: AppBuilder.Item { get }
}

@_functionBuilder public struct AppBuilder {
    public enum Item {
        case none
        case middleware(Middleware)
        case httpServer(HTTPServer)
        case logger(Logger.Declarative)
        case manualConfiguration(ManualConfiguration)
        case routes(Routes)
        case items([Self])
    }
    
    struct Content: AppBuilderContent {
        let appBuilderContent: Item
    }
    
    public typealias Result = AppBuilderContent
    public typealias Block = () -> Result

    public static func buildBlock() -> Result {
        Content(appBuilderContent: .none)
    }

    public static func buildBlock(_ attrs: Result...) -> Result {
        buildBlock(attrs)
    }

    public static func buildBlock(_ attrs: [Result]) -> Result {
        Content(appBuilderContent: .items(attrs.map { $0.appBuilderContent }))
    }

    public static func buildIf(_ content: Result?) -> Result {
        guard let content = content else { return Content(appBuilderContent: .none) }
        return Content(appBuilderContent: .items([content.appBuilderContent]))
    }

    public static func buildEither(first: Result) -> Result {
        Content(appBuilderContent: .items([first.appBuilderContent]))
    }

    public static func buildEither(second: Result) -> Result {
        Content(appBuilderContent: .items([second.appBuilderContent]))
    }
}

extension Application {
    public func setup(_ content: AppBuilderContent) throws -> Self {
        try content.appBuilderContent.setup(self, content)
        return self
    }
}

extension AppBuilder.Item {
    func setup(_ app: Application, _ content: AppBuilderContent) throws {
        func parseAppBody(_ item: AppBuilder.Item) throws {
            switch item {
            case .middleware(let mw):
                app.middleware.use(mw)
            case .httpServer(let server):
                server._apply(app)
            case .logger(let logger):
                app.logger.logLevel = logger.level
            case .manualConfiguration(let config):
                try config.handler(app)
            case .routes(let routes):
                routes.execute(app)
            case .items(let items):
                try items.forEach { try parseAppBody($0) }
            case .none: break
            }
        }
        try parseAppBody(content.appBuilderContent)
    }
}
