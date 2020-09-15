//
//  FileMiddleware.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

extension FileMiddleware: AppBuilderContent {
    public var appBuilderContent: AppBuilder.Item { .middleware(self) }
    
    public convenience init () {
        self.init(publicDirectory: "Public")
    }
    
    public static func publicDirectory(_ v: String) -> FileMiddleware {
        FileMiddleware(publicDirectory: v)
    }
}
