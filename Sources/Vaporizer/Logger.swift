//
//  Logger.swift
//  App
//
//  Created by Mihael Isaev on 14.09.2020.
//

import Vapor

extension Logger {
    public struct Declarative: AppBuilderContent {
        public var appBuilderContent: AppBuilder.Item { .logger(self) }
        
        var level: Level
        
        fileprivate init (_ v: Level) {
            level = v
        }
    }
    
    public static func level(_ v: Level) -> Declarative {
        .init(v)
    }
}
