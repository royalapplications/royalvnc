// swift-tools-version: 6.0

import PackageDescription

// swift-tools-version: 6.0

import PackageDescription

#if os(Windows)
let thisFilePath = #filePath
let depsWindowsPath = "\(thisFilePath)\\bin\\deps-windows"

let cSettings: [CSetting]? = [
    .unsafeFlags([
        "-I\(depsWindowsPath)\\include"
    ])
]
let linkerSettings: [LinkerSetting]? = [
    .unsafeFlags([
        "-L./\(depsWindowsPath)\\lib"
    ])
]

let libtommathTarget = Target.systemLibrary(name: "libtommath", path: "Sources/libtommath-win")
let libtomcryptTarget = Target.systemLibrary(name: "libtomcrypt", path: "Sources/libtomcrypt-win")
let zTarget = Target.systemLibrary(name: "Z", path: "Sources/Z-win")
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
            name: "RoyalVNCKitC"
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
            dependencies: [ "RoyalVNCKit" ]
        ),
        
        .executableTarget(
            name: "RoyalVNCKitCDemo",
            dependencies: [ "RoyalVNCKit" ]
        )
    ]
)
