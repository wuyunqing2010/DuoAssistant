// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PurchaseCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "PurchaseCore", targets: ["PurchaseCore"])],
    targets: [
        .target(name: "PurchaseCore"),
        .testTarget(name: "PurchaseCoreTests", dependencies: ["PurchaseCore"],
                    resources: [.process("Fixtures")])
    ]
)
