// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Appboy",
    platforms: [ .iOS(.v12), .tvOS(.v12) ],
    products: [
        .library(
            name: "mParticle-Appboy",
            targets: ["mParticle-Appboy"]),
        .library(
            name: "mParticle-Appboy-NoLocation",
            targets: ["mParticle-Appboy-NoLocation"]
        )
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.19.0")),
      .package(name: "braze-swift-sdk",
               url: "https://github.com/braze-inc/braze-swift-sdk",
               .upToNextMajor(from: "9.0.0")),
    ],
    targets: [
        .target(
            name: "mParticle-Appboy",
            dependencies: [
              .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
              .product(name: "BrazeUI", package: "braze-swift-sdk", condition: .when(platforms: [.iOS])),
              .product(name: "BrazeKit", package: "braze-swift-sdk"),
              .product(name: "BrazeKitCompat", package: "braze-swift-sdk"),
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "mParticle-Appboy-NoLocation",
            dependencies: [
              .product(name: "mParticle-Apple-SDK-NoLocation", package: "mParticle-Apple-SDK"),
              .product(name: "BrazeUI", package: "braze-swift-sdk", condition: .when(platforms: [.iOS])),
              .product(name: "BrazeKit", package: "braze-swift-sdk"),
              .product(name: "BrazeKitCompat", package: "braze-swift-sdk"),
            ],
            path: "SPM/mParticle-Appboy-NoLocation",
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)
