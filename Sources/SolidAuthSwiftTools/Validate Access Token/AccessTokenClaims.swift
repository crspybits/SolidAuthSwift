//
//  AccessTokenClaims.swift
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

// Body claims for access token

public struct AccessTokenClaims: JWTPayload {
    struct JKT: Codable {
        var jkt: String?
    }

    var iss: String?
    var aud: String?
    var sub: String?
    var exp: Date?
    var iat: Date?
    var nbf: Date?
    var jti: String?
    var cnf: JKT?
    var client_id: String?
    var webid: String?
    
    public func verify(using signer: JWTSigner) throws {
        // nop; use validateClaims in ValidateAccessToken
    }
}

