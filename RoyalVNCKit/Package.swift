// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RoyalVNCKit",
    
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
        .macCatalyst(.v15),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    
    products: [
        .library(
            name: "RoyalVNCKit",
            type: .dynamic,
            targets: [ "RoyalVNCKit" ]
        ),
    ],
    
    targets: [
        .target(
            name: "RoyalVNCKit",
            dependencies: [
                "d3des",
                "libtommath"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        
        .target(name: "d3des"),
        .target(name: "libtommath")
    ]
)
