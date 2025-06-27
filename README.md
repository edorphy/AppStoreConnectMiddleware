# AppStoreConnectMiddleware

A Swift package for attaching signed JWTs as authorization headers to requests for the App Store Connect API. 

## Features
- Middleware to sign HTTP requests for the App Store Connect API with ES256 (P-256) JWTs
- Supports both team-based and individual Apple API keys
- Designed with Swift Concurrency and Sendable safety

## Requirements
- Swift 6.0 or newer
- iOS 18+, macOS 15+, visionOS 2+
