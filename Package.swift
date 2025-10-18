// swift-tools-version: 6.0

import PackageDescription

let swiftLanguageMode = SwiftLanguageMode.v5

let cSettings: [CSetting]
let zTarget: Target

#if os(Windows)
// Sources\libtommath\bignumshim.c:28:10: warning: 'mp_read_unsigned_bin' is deprecated: replaced by mp_from_ubin [-Wdeprecated-declarations]
// Sources\libtomcrypt\mac\xcbc\xcbc_file.c:55:9: warning: 'fopen' is deprecated: This function or variable may be unsafe. Consider using fopen_s instead. [-Wdeprecated-declarations]
let disableDeprecatedDeclarationsWarning = "-Wno-deprecated-declarations"

// Sources\libtomcrypt\include\tomcrypt_cfg.h:27:28: warning: 'malloc' redeclared without 'dllimport' attribute: previous 'dllimport' ignored [-Winconsistent-dllimport]
// Sources\libtomcrypt\include\tomcrypt_cfg.h:28:28: warning: 'realloc' redeclared without 'dllimport' attribute: previous 'dllimport' ignored [-Winconsistent-dllimport]
let disableInconsistentDllImportWarning = "-Wno-inconsistent-dllimport"

cSettings = [
    .unsafeFlags([
        disableDeprecatedDeclarationsWarning,
        disableInconsistentDllImportWarning
    ])
]

zTarget = Target.target(name: "Z", path: "Sources/zlib-1.3.1", cSettings: [
    .define("STDC"),
    .define("HAVE_STDARG_H"),
    .define("HAVE_HIDDEN"),

    .unsafeFlags([
        disableDeprecatedDeclarationsWarning,
    ])
])
#else
cSettings = .init()

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
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.9.0")
    ],

    targets: [
        .target(
            name: "RoyalVNCKitC",
            cSettings: cSettings
        ),

        .target(
            name: "RoyalVNCKit",

            dependencies: [
                "RoyalVNCKitC",
                .byName(name: d3desTarget.name),
                .byName(name: zTarget.name),
                .byName(name: "CryptoSwift")
            ],

            cSettings: cSettings,
            
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
            dependencies: [ "RoyalVNCKit" ],

            cSettings: cSettings
        ),

        .executableTarget(
            name: "RoyalVNCKitCDemo",
            dependencies: [ "RoyalVNCKit" ],

            cSettings: cSettings
        )
    ]
)
