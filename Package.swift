// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyLibrary",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MyLibrary",
            targets: ["MyLibrary"]),
        
        
        .library(name: "CoreDataKit", targets: ["CoreDataKit"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "NavigationRouter", targets: ["NavigationRouter"]),
        //.library(name: "ThemeGlassKit", targets: ["ThemeGlassKit"]),
        .library(name: "GlassEffect", targets: ["GlassEffect"]),
        
        
        .library(name: "UIComponents", targets: ["UIComponents"]),
        
        .library(
            name: "GeminiAI",
            targets: ["GeminiAI"]),
        .library(
            name: "RoutablePage",
            targets: ["RoutablePage"]),
        .library(
            name: "SwipeActions",
            targets: ["SwipeActions"]),
        .library(
            name: "WebView",
            targets: ["WebView"]),
        .library(
            name: "DeviceRotation",
            targets: ["DeviceRotation"]),
        .library(name: "OTPCode", targets: ["OTPCode"]),
        
        .library(name: "TextToSpeech", targets: ["TextToSpeech"]),
        
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
        .package(url: "https://github.com/google-gemini/generative-ai-swift", .upToNextMajor(from: "0.5.6")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        
        .target(name: "MyLibrary", dependencies: ["Alamofire"]),
        .target(name: "CoreDataKit", dependencies: []),
        
        .target(name: "Networking", dependencies: ["Alamofire"]),
        .target(name: "NavigationRouter", dependencies: []),
        //.target(name: "ThemeGlassKit", dependencies: []),
        .target(name: "GlassEffect", dependencies: []),
        
        .target(name: "UIComponents", dependencies: []),
        
        .target(
            name: "GeminiAI",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ]),
        .target(
            name: "RoutablePage",
            dependencies: []),
        .target(
            name: "SwipeActions",
            dependencies: []),
        .target(
            name: "WebView",
            dependencies: []),
        .target(
            name: "DeviceRotation",
            dependencies: []),
        .target(
            name: "OTPCode",
            dependencies: []),
        
        //.target(name: "Toasts", dependencies: []),
        //.target(name: "ChipsSelection", dependencies: []),
        //.target(name: "InteractiveSideMenu", dependencies: []),
        //.target(name: "TripCard", dependencies: []),
        
        .target(name: "TextToSpeech", dependencies: []),
        
    ]
)

