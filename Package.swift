// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CougarSwift",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "CougarSwift",
            targets: ["CougarSwift"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            exact: "2.46.0"
        ),
    ],
    targets: [
        .target(
            name: "CougarSwift",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "CougarSwiftTests",
            dependencies: ["CougarSwift"]
        ),
    ]
)
