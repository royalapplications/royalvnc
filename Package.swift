// swift-tools-version: 6.0

import PackageDescription

#if os(Windows)
// Sources\libtommath\bignumshim.c:28:10: warning: 'mp_read_unsigned_bin' is deprecated: replaced by mp_from_ubin [-Wdeprecated-declarations]
// Sources\libtomcrypt\mac\xcbc\xcbc_file.c:55:9: warning: 'fopen' is deprecated: This function or variable may be unsafe. Consider using fopen_s instead. [-Wdeprecated-declarations]
let disableDeprecatedDeclarationsWarning = "-Wno-deprecated-declarations"

// Sources\libtomcrypt\include\tomcrypt_cfg.h:27:28: warning: 'malloc' redeclared without 'dllimport' attribute: previous 'dllimport' ignored [-Winconsistent-dllimport]
// Sources\libtomcrypt\include\tomcrypt_cfg.h:28:28: warning: 'realloc' redeclared without 'dllimport' attribute: previous 'dllimport' ignored [-Winconsistent-dllimport]
let disableInconsistentDllImportWarning = "-Wno-inconsistent-dllimport"

let cSettings: [CSetting]? = [
    .unsafeFlags([
        disableDeprecatedDeclarationsWarning,
        disableInconsistentDllImportWarning
    ])
]
let linkerSettings: [LinkerSetting]? = []


let libtommathTarget = Target.target(name: "libtommath", cSettings: [
    .unsafeFlags([
        disableDeprecatedDeclarationsWarning
    ])
])
let libtomcryptTarget = Target.target(name: "libtomcrypt", cSettings: [
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        disableDeprecatedDeclarationsWarning,
        disableInconsistentDllImportWarning
    ])
])
let zTarget = Target.target(name: "Z", path: "Sources/zlib-1.3.1", cSettings: [
    .define("STDC"),
    .define("HAVE_STDARG_H"), 
    .define("HAVE_HIDDEN"),
    .unsafeFlags([
        disableDeprecatedDeclarationsWarning,
    ])
])
#else
let cSettings: [CSetting]? = []
let linkerSettings: [LinkerSetting]? = []

let libtommathTarget = Target.target(name: "libtommath")
let libtomcryptTarget = Target.target(name: "libtomcrypt", cSettings: [
    .unsafeFlags([ "-Wno-shorten-64-to-32" ])
])
let zTarget = Target.target(name: "Z", linkerSettings: [
    .linkedLibrary("z")
])
#endif

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
            name: "RoyalVNCKitC",

            cSettings: cSettings,
            linkerSettings: linkerSettings
       ),
        
        .target(
            name: "RoyalVNCKit",
            
            dependencies: [
                "RoyalVNCKitC",
                "d3des",
                .byName(name: libtommathTarget.name),
                .byName(name: libtomcryptTarget.name),
                .byName(name: zTarget.name)
            ],
            
            cSettings: cSettings,
            swiftSettings: [ .swiftLanguageMode(.v5) ],
            linkerSettings: linkerSettings
        ),
        
        .target(name: "d3des"),
        libtommathTarget,
        libtomcryptTarget,
        zTarget,
        
        .executableTarget(
            name: "RoyalVNCKitDemo",
            dependencies: [ "RoyalVNCKit" ],

            cSettings: cSettings,
            linkerSettings: linkerSettings
        ),
        
        .executableTarget(
            name: "RoyalVNCKitCDemo",
            dependencies: [ "RoyalVNCKit" ],

            cSettings: cSettings,
            linkerSettings: linkerSettings
        )
    ]
)
