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
    
    enum CodingKeys: String, CodingKey {
        case iss
        case aud
        case sub
        case exp
        case iat
        case nbf
        case jti
        case cnf
        case client_id
        case webid
    }

    public var iss: String?
    
    // https://solid.github.io/solid-oidc/#tokens-access
    // "aud — The audience claim MUST either be the string solid or be an array of values, one of which is the string solid. In the decentralized world of Solid OIDC, the principal of an access token is not a specific endpoint, but rather the Solid API; that is, any Solid server at any accessible address on the world wide web. See also: JSON Web Token (JWT) § section-4.1.3."
    public enum Aud {
        case single(String)
        case array([String])
    }
    
    public var aud: Aud?
    
    public var sub: String?
    public var exp: Date?
    public var iat: Date?
    public var nbf: Date?
    public var jti: String?
    public var cnf: JKT?
    public var client_id: String?
    public var webid: String?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        iss = try container.decodeIfPresent(String.self, forKey: .iss)
        
        do {
            if let single = try container.decodeIfPresent(String.self, forKey: .aud) {
                aud = .single(single)
            }
        } catch DecodingError.typeMismatch {
            if let array = try container.decodeIfPresent([String].self, forKey: .aud) {
                aud = .array(array)
            }
        }
        
        sub = try container.decodeIfPresent(String.self, forKey: .sub)
        exp = try container.decodeIfPresent(Date.self, forKey: .exp)
        iat = try container.decodeIfPresent(Date.self, forKey: .iat)
        nbf = try container.decodeIfPresent(Date.self, forKey: .nbf)
        jti = try container.decodeIfPresent(String.self, forKey: .jti)
        cnf = try container.decodeIfPresent(JKT.self, forKey: .cnf)
        client_id = try container.decodeIfPresent(String.self, forKey: .client_id)
        webid = try container.decodeIfPresent(String.self, forKey: .webid)
    }
    
    public func encode(to encoder: Encoder) throws {
        // Not implemented; not used.
    }
    
    public func verify(using signer: JWTSigner) throws {
        // nop; use validateClaims in Token
    }
}

