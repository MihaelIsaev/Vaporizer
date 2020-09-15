// swift-tools-version:5.2
import PackageDescription
import Foundation

// MARK: - Conveniences

let localDev = ProcessInfo.processInfo.environment["LIBS_DEVELOPMENT"] == "1"
let devDir = "../"

struct Dep {
    let package: PackageDescription.Package.Dependency
    let targets: [Target.Dependency]
}

extension Array where Element == Dep {
    mutating func appendLocal(_ path: String, targets: Target.Dependency...) {
        append(.init(package: .package(path: "\(devDir)\(path)"), targets: targets))
    }

    mutating func append(_ url: String, from: Version, targets: Target.Dependency...) {
        append(.init(package: .package(url: url, from: from), targets: targets))
    }

    mutating func append(_ url: String, _ requirement: PackageDescription.Package.Dependency.Requirement, targets: Target.Dependency...) {
        append(.init(package: .package(url: url, requirement), targets: targets))
    }
}

// MARK: - Dependencies

var deps: [Dep] = []

deps.append("https://github.com/vapor/vapor.git", from: "4.0.0", targets: .product(name: "Vapor", package: "vapor"))

// MARK: - Package

let package = Package(
    name: "Vaporizer",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Vaporizer", targets: ["Vaporizer"]),
    ],
    dependencies: deps.map { $0.package },
    targets: [
        .target(name: "Vaporizer", dependencies: deps.flatMap { $0.targets }),
        .testTarget(name: "VaporizerTests", dependencies: [.target(name: "Vaporizer")]),
    ]
)
