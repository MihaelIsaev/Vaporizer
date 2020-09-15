//
//  ManualConfiguration.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

public struct ManualConfiguration: AppBuilderContent {
    public var appBuilderContent: AppBuilder.Item { .manualConfiguration(self) }
    
    let handler: (Application) throws -> Void
    
    public init (_ handler: @escaping (Application) throws -> Void) {
        self.handler = handler
    }
}
