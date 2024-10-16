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
            name: "RoyalVNCKit",
            
            dependencies: [
                "d3des",
                "libtommath",
                "libtomcrypt",
                "Z",
                .byName(name: "OpenSSL", condition: .when(platforms: [ .linux ]))
            ],
            
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        
        .target(name: "d3des"),
        .target(name: "libtommath"),
        .target(name: "libtomcrypt"),
        
        .target(name: "Z", linkerSettings: [
            .linkedLibrary("z")
        ]),

        .target(name: "OpenSSL", linkerSettings: [
            .linkedLibrary("ssl"),
            .linkedLibrary("crypto")
        ]),
        
        .executableTarget(
            name: "RoyalVNCKitDemo",
            
            dependencies: [
                "RoyalVNCKit"
            ]
        )
    ]
)
