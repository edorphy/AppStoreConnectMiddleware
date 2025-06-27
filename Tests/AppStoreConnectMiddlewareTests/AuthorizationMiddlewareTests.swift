//
//  AuthorizationMiddlewareTests.swift
//  AppStoreConnectMiddlewareTests
//
//  Created by Eric Dorphy on 6/27/25.
//  Copyright © 2025 Twin Cities App Dev LLC. All rights reserved.
//

import CryptoKit
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import AppStoreConnectMiddleware

struct AuthorizationMiddlewareTests {
    @Test func testIndividualKeyMiddlewareAddsAuthorizationHeader() async throws {
        let keyID = "keyID"
        let privateKey = P256.Signing.PrivateKey()
        let middleware = AuthorizationMiddleware(keyID: keyID) { privateKey }

        try await assertAuthorizationHeaderIsSet(middleware: middleware)
    }

    @Test func testTeamKeyMiddlewareAddsAuthorizationHeader() async throws {
        let keyID = "keyID"
        let issuerID = "issuerID"
        let privateKey = P256.Signing.PrivateKey()
        let middleware = AuthorizationMiddleware(keyID: keyID, issuerID: issuerID) { privateKey }

        try await assertAuthorizationHeaderIsSet(middleware: middleware)
    }

    @Test
    func testEquatableSameProperties() {
        let closure: @Sendable () -> P256.Signing.PrivateKey = { P256.Signing.PrivateKey() }
        let middleware1 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        let middleware2 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        #expect(middleware1 == middleware2)
    }

    @Test
    func testEquatableDifferentProperties() {
        let closure: @Sendable () -> P256.Signing.PrivateKey = { P256.Signing.PrivateKey() }
        let middleware1 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        let middleware2 = AuthorizationMiddleware(keyID: "key2", issuerID: "issuer2", signingPrivateKey: closure)
        #expect(middleware1 != middleware2)
    }

    @Test
    func testHashableEquality() {
        let closure: @Sendable () -> P256.Signing.PrivateKey = { P256.Signing.PrivateKey() }
        let middleware1 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        let middleware2 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        #expect(middleware1.hashValue == middleware2.hashValue)
    }

    @Test
    func testHashableInequality() {
        let closure: @Sendable () -> P256.Signing.PrivateKey = { P256.Signing.PrivateKey() }
        let middleware1 = AuthorizationMiddleware(keyID: "key1", issuerID: "issuer1", signingPrivateKey: closure)
        let middleware2 = AuthorizationMiddleware(keyID: "key2", issuerID: "issuer2", signingPrivateKey: closure)
        #expect(middleware1.hashValue != middleware2.hashValue)
    }

    private func assertAuthorizationHeaderIsSet(middleware: AuthorizationMiddleware) async throws {
        var interceptedHeader: String? = nil

        let request = HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/")
        let body: HTTPBody? = nil
        let baseURL = Foundation.URL(string: "https://example.com")!
        let operationID = "testOperation"

        let next: (HTTPRequest, HTTPBody?, Foundation.URL) async throws -> (HTTPResponse, HTTPBody?) = { modifiedRequest, body, baseURL in
            interceptedHeader = modifiedRequest.headerFields[.authorization]
            return (HTTPResponse(status: .ok), nil)
        }

        _ = try await middleware.intercept(request, body: body, baseURL: baseURL, operationID: operationID, next: next)

        try #require(interceptedHeader != nil, "Authorization header should be set")
        try #require(interceptedHeader?.starts(with: "Bearer ") == true, "Authorization header should start with 'Bearer '")
    }
}
