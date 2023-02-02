// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Appboy",
    platforms: [ .iOS(.v9) ],
    products: [
        .library(
            name: "mParticle-Appboy",
            targets: ["mParticle-Appboy"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.0.0")),
      .package(name: "braze-swift-sdk",
               url: "https://github.com/braze-inc/braze-swift-sdk",
               .upToNextMajor(from: "5.9.0")),
    ],
    targets: [
        .target(
            name: "mParticle-Appboy",
            dependencies: [
              .byName(name: "mParticle-Apple-SDK"),
              .product(name: "AppboyUI", package: "Appboy_iOS_SDK"),
            ]
        )
    ]
)
