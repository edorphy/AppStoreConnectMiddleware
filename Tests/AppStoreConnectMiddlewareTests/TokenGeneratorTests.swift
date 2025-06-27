//
//  TokenGeneratorTests.swift
//  AppStoreConnectMiddlewareTests
//
//  Created by Eric Dorphy on 6/26/25.
//  Copyright © 2025 Twin Cities App Dev LLC. All rights reserved.
//

@testable import AppStoreConnectMiddleware
import CryptoKit
import Testing
import HTTPTypes

struct TokenGeneratorTests {
    @Test func generateIndividualToken() throws {
        let signingPrivateKey = P256.Signing.PrivateKey()

        _ = try TokenGenerator.generate(keyID: "keyID", keyType: .individual, signingPrivateKey: signingPrivateKey)
    }

    @Test func generateTeamToken() throws {
        let signingPrivateKey = P256.Signing.PrivateKey()

        _ = try TokenGenerator.generate(keyID: "keyID", keyType: .team(issuerID: "issuerID"), signingPrivateKey: signingPrivateKey)
    }
}
