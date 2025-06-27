//
//  AuthorizationMiddleware.swift
//  AppStoreConnectMiddleware
//
//  Created by Eric Dorphy on 6/26/25.
//  Copyright © 2025 Twin Cities App Dev LLC. All rights reserved.
//

import CryptoKit
import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A middleware type that attaches a signed JWT to requests for authenticating with the App Store Connect API.
///
/// This type supports both team-based and individual keys for signing.
/// Tokens are signed using the ES256 algorithm with a P-256 private key, and are added as a Bearer token
/// in the `Authorization` header of each outgoing request.
public struct AuthorizationMiddleware: Equatable, Hashable, Sendable {
    private let keyType: KeyType
    private let keyID: String
    private let signingPrivateKey: @Sendable () throws -> P256.Signing.PrivateKey

    /// Creates middleware using a team-based App Store Connect API key.
    ///
    /// - Parameters:
    ///   - keyID: The 10-character Key ID associated with the private key in App Store Connect.
    ///   - issuerID: The 10-character Issuer ID associated with your App Store Connect API key.
    ///   - signingPrivateKey: A closure that returns a valid `P256.Signing.PrivateKey` for signing tokens.
    public init(
        keyID: String,
        issuerID: String,
        signingPrivateKey: @escaping @Sendable () throws -> P256.Signing.PrivateKey
    ) {
        self.init(keyID: keyID, keyType: .team(issuerID: issuerID), signingPrivateKey: signingPrivateKey)
    }

    /// Creates middleware using an individual App Store Connect API key.
    ///
    /// - Parameters:
    ///   - keyID: The 10-character Key ID associated with the private key in App Store Connect.
    ///   - signingPrivateKey: A closure that returns a valid `P256.Signing.PrivateKey` for signing tokens.
    public init(
        keyID: String,
        signingPrivateKey: @escaping @Sendable () throws -> P256.Signing.PrivateKey
    ) {
        self.init(keyID: keyID, keyType: .individual, signingPrivateKey: signingPrivateKey)
    }

    // Internal initializer used when the key type is already known.
    init(
        keyID: String,
        keyType: KeyType,
        signingPrivateKey: @escaping @Sendable () throws -> P256.Signing.PrivateKey
    ) {
        self.keyID = keyID
        self.keyType = keyType
        self.signingPrivateKey = signingPrivateKey
    }

    /// Hashes the key ID and key type into the given hasher.
    ///
    /// The private signing key is not included in the hash.
    /// This is sufficient to uniquely identify instances for caching or deduplication logic.
    ///
    /// - Parameter hasher: The hasher to use for combining components.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyType)
        hasher.combine(keyID)
    }

    /// Returns whether two middleware instances are equal.
    ///
    /// Equality is based on `keyType` and `keyID`. The signing key itself is not compared.
    ///
    /// - Parameters:
    ///   - lhs: A middleware instance to compare.
    ///   - rhs: Another middleware instance to compare.
    /// - Returns: `true` if both middleware instances share the same key type and key ID.
    public static func == (lhs: AuthorizationMiddleware, rhs: AuthorizationMiddleware) -> Bool {
        lhs.keyType == rhs.keyType && lhs.keyID == rhs.keyID
    }
}

extension AuthorizationMiddleware: ClientMiddleware {
    /// Intercepts an outgoing request and attaches a signed JWT token as an Authorization header.
    ///
    /// The token is generated using the current `signingPrivateKey` and scoped to the App Store Connect API.
    ///
    /// - Parameters:
    ///   - request: The original HTTP request.
    ///   - body: The optional HTTP body.
    ///   - baseURL: The base URL used by the request.
    ///   - operationID: The OpenAPI operation identifier. Unused in this implementation.
    ///   - next: A closure to invoke the next step in the request pipeline.
    ///
    /// - Returns: A tuple containing the HTTP response and optional response body.
    /// - Throws: Any errors encountered during signing or forwarding the request.
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let signingPrivateKey = try signingPrivateKey()
        let token = try TokenGenerator.generate(
            keyID: keyID,
            keyType: keyType,
            signingPrivateKey: signingPrivateKey,
            issuedAt: .now,
            expirationInterval: 20 * 60
        )

        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"

        return try await next(request, body, baseURL)
    }
}
