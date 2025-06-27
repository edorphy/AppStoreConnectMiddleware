//
//  KeyType.swift
//  AppStoreConnectMiddleware
//
//  Created by Eric Dorphy on 6/26/25.
//  Copyright © 2025 Twin Cities App Dev LLC. All rights reserved.
//

import Foundation

enum KeyType: Equatable, Hashable, Sendable {
    case team(issuerID: String)
    case individual
}
