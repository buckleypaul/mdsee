// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mdsee",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "mdsee",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            resources: [
                .copy("Resources/template.html")
            ]
        ),
    ]
)
