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
        .library(
            name: "OTPCode",
            targets: ["OTPCode"]),
        .library(
            name: "Toasts",
            targets: ["Toasts"]),
        
        
        
        
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
        .package(url: "https://github.com/google-gemini/generative-ai-swift", .upToNextMajor(from: "0.5.6")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MyLibrary",
            dependencies: [
                            // Liên kết target với Alamofire
                            "Alamofire"
                        ]),
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
        .target(
            name: "Toasts",
            dependencies: []),
        
    ]
)

