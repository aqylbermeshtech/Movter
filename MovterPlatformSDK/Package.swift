// swift-tools-version: 5.9
//
//  Package.swift
//  Movter
//
//  Created by Nurtore on 10.10.2026.
//

import PackageDescription

let package = Package(
    name: "MovterPlatformSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "MovterCore", targets: ["MovterCore"]),
        .library(name: "MovterDomain", targets: ["MovterDomain"]),
        .library(name: "MovterNetwork", targets: ["MovterNetwork"]),
        .library(name: "MovterStorage", targets: ["MovterStorage"]),
        .library(name: "MovterUI", targets: ["MovterUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.10.0"),
        .package(url: "https://github.com/SwiftfulThinking/SwiftfulLoadingIndicators.git", from: "0.0.4")
    ],
    targets: [
        .target(
            name: "MovterCore",
            dependencies: [
                .product(name: "Swinject", package: "Swinject")
            ],
            path: "Sources/MovterCore"
        ),
        .target(
            name: "MovterStorage",
            dependencies: [
                "MovterCore"
            ],
            path: "Sources/MovterStorage"
        ),
        .target(
            name: "MovterNetwork",
            dependencies: [
                "MovterCore",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/MovterNetwork"
        ),
        .target(
            name: "MovterDomain",
            dependencies: [
                "MovterCore"
            ],
            path: "Sources/MovterDomain"
        ),
        .target(
            name: "MovterUI",
            dependencies: [
                "MovterCore",
                .product(name: "SwiftfulLoadingIndicators", package: "SwiftfulLoadingIndicators")
            ],
            path: "Sources/MovterUI"
        )
    ]
)
