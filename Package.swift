// swift-tools-version: 6.0

import PackageDescription

let swiftLanguageMode = SwiftLanguageMode.v5
let zTarget: Target

#if os(Windows)
let disableDeprecatedDeclarationsWarning = "-Wno-deprecated-declarations"

zTarget = Target.target(name: "Z", path: "Sources/zlib-1.3.1", cSettings: [
    .define("STDC"),
    .define("HAVE_STDARG_H"),
    .define("HAVE_HIDDEN"),

    .unsafeFlags([
        disableDeprecatedDeclarationsWarning,
    ])
])
#else
zTarget = Target.target(name: "Z", linkerSettings: [
    .linkedLibrary("z")
])
#endif

let d3desTarget = Target.target(name: "d3des")

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
    
    dependencies: [
        // TODO: Switch back to main repo once our FoundationEssentials changes are merged upstream
        .package(url: "https://github.com/royalapplications/CryptoSwift.git", branch: "foundationessentials"),
        .package(url: "https://github.com/tayloraswift/swift-jpeg", from: "2.0.0"),
        .package(url: "https://github.com/tayloraswift/swift-png", from: "4.4.0")
//        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.9.0")
    ],

    targets: [
        .target(
            name: "RoyalVNCKitC"
        ),

        .target(
            name: "RoyalVNCKit",

            dependencies: [
                "RoyalVNCKitC",
                .byName(name: d3desTarget.name),
                .byName(name: zTarget.name),
                .byName(name: "CryptoSwift"),
                .product(name: "JPEG", package: "swift-jpeg"),
                .product(name: "PNG", package: "swift-png")
            ],

            swiftSettings: [
                .swiftLanguageMode(swiftLanguageMode),
                
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),

        d3desTarget,
        zTarget,

        .executableTarget(
            name: "RoyalVNCKitDemo",
            dependencies: [ "RoyalVNCKit" ]
        ),

        .executableTarget(
            name: "RoyalVNCKitCDemo",
            dependencies: [ "RoyalVNCKit" ]
        )
    ]
)
