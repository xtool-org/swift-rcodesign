// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rcodesign",
    platforms: [.macOS(.v11), .iOS(.v15)],
    products: [
        .library(name: "RCodesign", targets: ["RCodesign"])
    ],
    targets: [
        .target(
            name: "RCodesign",
            dependencies: ["RCodesignBinary"],
            linkerSettings: [
                .linkedFramework("Security", .when(platforms: [.macOS, .iOS])),
                .linkedFramework("CoreFoundation", .when(platforms: [.macOS, .iOS])),
                .linkedLibrary("iconv", .when(platforms: [.macOS, .iOS])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("rt", .when(platforms: [.linux])),
                .linkedLibrary("util", .when(platforms: [.linux]))
            ]
        ),
        .binaryTarget(
            name: "RCodesignBinary",
            url: "https://github.com/xtool-org/swift-rcodesign/releases/download/source-0.1.0/RCodesignBinary.artifactbundle.zip",
            checksum: "5cad6cf14654428e112eddfc7c71e58c371579be8c3ea5f9deadb7dfcd099048"
        ),
        .testTarget(name: "RCodesignTests", dependencies: ["RCodesign"])
    ]
)
