// swift-tools-version: 5.9

import PackageDescription

let resources: Target.Dependency = .product(name: "AzkarResources", package: "Core")
let entities: Target.Dependency = .product(name: "Entities", package: "Core")
let extensions: Target.Dependency = .product(name: "Extensions", package: "Core")
let azkarServices: Target.Dependency = .product(name: "AzkarServices", package: "Core")
let databaseInteractors = Target.Dependency.product(name: "DatabaseInteractors", package: "Interactors")

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "Library", targets: ["Library"]),
        .library(name: "Components", targets: ["Components"]),
        .library(name: "AboutApp", targets: ["AboutApp"]),
        .library(name: "ArticleReader", targets: ["ArticleReader"]),
        .library(name: "AudioPlayer", targets: ["AudioPlayer"]),
        .library(name: "ZikrCollectionsOnboarding", targets: ["ZikrCollectionsOnboarding"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Interactors"),

        // MARK: Services.
        .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.35.0"),
                
        // MARK: Utilities.
        .package(url: "https://github.com/rundfunk47/stinsen", from: "2.0.13"),
        .package(url: "https://github.com/vadymmarkov/Fakery", from: "5.1.0"),
        .package(url: "https://github.com/kean/Nuke", from: "12.8.0"),
        .package(url: "https://github.com/onmyway133/RoughSwift", from: "2.0.0"),
        .package(url: "https://github.com/mannylopez/TinyMoon", from: "3.0.1"),
        
        // MARK: UI.
        .package(url: "https://github.com/aheze/Popovers", from: "1.3.2"),
        .package(url: "https://github.com/airbnb/lottie-spm", from: "4.5.2"),
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "26.0.0"),
        .package(url: "https://github.com/shaps80/SwiftUIBackports", from: "2.8.1"),
        .package(url: "https://github.com/bmoliveira/MarkdownKit", from: "1.7.3"),
    ],
    targets: [
        .target(
            name: "AudioPlayer",
            dependencies: []
        ),
        .target(
            name: "Library",
            dependencies: [
                resources,
                entities,
                extensions,
                azkarServices,
                databaseInteractors,
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "NukeUI", package: "Nuke"),
                "TinyMoon",
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
            ]
        ),
        .target(
            name: "Components",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm"),
            ]
        ),
        .target(name: "ArticleReader", dependencies: [
            entities,
            extensions,
            azkarServices,
            "Library",
            "RoughSwift",
            "Popovers",
            "MarkdownKit",
            .product(name: "Fakery", package: "Fakery"),
            .product(name: "NukeUI", package: "Nuke"),
        ]),
        .target(name: "AboutApp", dependencies: [
            entities,
            extensions,
            azkarServices,
            "Library",
        ]),
        .target(name: "ZikrCollectionsOnboarding", dependencies: [
            entities,
            "Library",
        ])
    ]
)
