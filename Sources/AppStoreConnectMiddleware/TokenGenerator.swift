//
//  TokenGenerator.swift
//  AppStoreConnectMiddleware
//
//  Created by Eric Dorphy on 6/26/25.
//  Copyright © 2025 Twin Cities App Dev LLC. All rights reserved.
//

import CryptoKit
import Foundation

enum TokenGenerator {
    /// Generates a signed JWT for App Store Connect API requests.
    ///
    /// - Parameters:
    ///   - keyID: The 10-character identifier of the private key (JWT `kid`).
    ///   - keyType: The authorization key type (`.team` with issuer ID, or `.individual`).
    ///   - signingPrivateKey: The P-256 private key used to sign the JWT.
    ///   - issuedAt: The issuance time of the token. Defaults to now.
    ///   - expirationInterval: The number of seconds the token is valid for. Defaults to 20 minutes.
    ///   - scope: Optional scope array. Usually not required for App Store Connect.
    /// - Returns: A JWT string in the format `header.payload.signature`, Base64URL-encoded.
    /// - Throws: If encoding or signing fails.
    static func generate(
        keyID: String,
        keyType: KeyType,
        signingPrivateKey: P256.Signing.PrivateKey,
        issuedAt: Date = .now,
        expirationInterval: TimeInterval = 20 * 60,
        scope: [String]? = nil
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        // Header
        let header = JWT.Header(keyID: keyID)
        let headerBase64 = try encoder.encode(header).base64URLEncodedString

        // Payload
        let payload = JWT.Payload(
            keyType: keyType,
            issuedAt: issuedAt,
            expirationInterval: expirationInterval,
            scope: scope
        )
        let payloadBase64 = try encoder.encode(payload).base64URLEncodedString

        // Signature
        let message = "\(headerBase64).\(payloadBase64)"
        let signature = try signingPrivateKey.signature(for: Data(message.utf8))
        let signatureBase64 = signature.rawRepresentation.base64URLEncodedString

        return "\(message).\(signatureBase64)"
    }
}

private enum JWT {
    struct Header: Encodable {
        private let alg: String = "ES256"
        private let kid: String
        private let typ: String = "JWT"

        init(keyID: String) {
            self.kid = keyID
        }
    }

    struct Payload: Encodable {
        private enum CodingKeys: String, CodingKey {
            case iss, sub, iat, exp, aud, scope
        }

        private let keyType: KeyType
        private let iat: Int
        private let exp: Int
        private let aud: String = "appstoreconnect-v1"
        private let scope: [String]?

        init(
            keyType: KeyType,
            issuedAt: Date = .now,
            expirationInterval: TimeInterval = 20 * 60,
            scope: [String]? = nil
        ) {
            self.keyType = keyType
            self.iat = Int(issuedAt.timeIntervalSince1970)
            self.exp = Int(issuedAt.addingTimeInterval(expirationInterval).timeIntervalSince1970)
            self.scope = scope
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch keyType {
            case .team(let issuerID):
                try container.encode(issuerID, forKey: .iss)

            case .individual:
                try container.encode("user", forKey: .sub)
            }

            try container.encode(iat, forKey: .iat)
            try container.encode(exp, forKey: .exp)
            try container.encode(aud, forKey: .aud)
            try container.encodeIfPresent(scope, forKey: .scope)
        }
    }
}

private extension Data {
    var base64URLEncodedString: String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
