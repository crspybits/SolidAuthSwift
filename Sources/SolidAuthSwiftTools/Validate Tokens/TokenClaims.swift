//
//  TokenClaims.swift
//  
//
//  Created by Christopher G Prince on 7/29/21.
//

import Foundation
import JWTKit

/*
{
    "alg": "RS256",
    "kid": "JqKos_btHpg"
}

{
    "iss": "https://solidcommunity.net",
    "aud": "solid",
    "sub": "https://crspybits.solidcommunity.net/profile/card#me",
    "exp": 1628821277,
    "iat": 1627611677,
    "jti": "53d95321255a8384",
    "cnf": {
        "jkt": "_JFFFM0JL94Ke6tkH4fOIvurV4QdQ8QBIPWjjGqyevU"
    },
    "client_id": "b26cd76023ba7d4392097287823413a2",
    "webid": "https://crspybits.solidcommunity.net/profile/card#me"
}
 */

// Body claims for access and id tokens

public struct TokenClaims: JWTPayload {
    public struct JKT: Codable {
        var jkt: String?
    }

    public var iss: String?
    public var aud: String?
    public var sub: String?
    public var exp: Date?
    public var iat: Date?
    public var nbf: Date?
    public var jti: String?
    public var cnf: JKT?
    public var client_id: String?
    public var webid: String?
    
    public func verify(using signer: JWTSigner) throws {
        // nop; use validateClaims in Token
    }
}

