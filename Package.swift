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
        
        .executable(name: "RoyalVNCKitDemo",
                    targets: [ "RoyalVNCKitDemo" ])
    ],

    targets: [
        .target(
            name: "RoyalVNCKitC"
        ),
        
        .target(
            name: "RoyalVNCKit",
            
            dependencies: [
                "RoyalVNCKitC",
                "d3des",
                "libtommath",
                "libtomcrypt",
                "Z"
            ],
            
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        
        .target(name: "d3des"),
        .target(name: "libtommath"),
        
        .target(name: "libtomcrypt", cSettings: [
            .unsafeFlags([
                "-Wno-shorten-64-to-32"
            ])
        ]),
        
        .target(name: "Z", linkerSettings: [
            .linkedLibrary("z")
        ]),
        
        .executableTarget(
            name: "RoyalVNCKitDemo",
            
            dependencies: [
                "RoyalVNCKit"
            ]
        )
    ]
)
