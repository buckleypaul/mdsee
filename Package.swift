// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mdsee",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "mdsee",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
            ],
            resources: [
                .copy("Resources/template.html"),
                .copy("Resources/themes")
            ]
        ),
    ]
)
