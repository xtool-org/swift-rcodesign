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
            url: "https://github.com/xtool-org/swift-rcodesign/releases/download/source-0.2.0/RCodesignBinary.artifactbundle.zip",
            checksum: "78735ce9e52740a67f1fffc8aa48c97578824fb87cc4a76ca1fc59d9197197e2"
        ),
        .testTarget(name: "RCodesignTests", dependencies: ["RCodesign"])
    ]
)
