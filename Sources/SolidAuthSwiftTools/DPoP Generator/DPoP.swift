//
//  DPoP.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
import SwiftJWT

// Header example, from:
// https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-13
/*
{
    "alg": "ES256",
    "typ": "dpop+jwt",
    "jwk": {
        "kty": "EC",
        "kid": "2i00gHnREsMhD5WqsABPSaqEjLC5MS-E98ykd-qtF1I",
        "use": "sig",
        "alg": "EC",
        "crv": "P-256",
        "x": "N6VsICiPA1ciAA82Jhv7ykkPL9B0ippUjmla8Snr4HY",
        "y": "ay9qDOrFGdGe_3hAivW5HnqHYdnYUkXJJevHOBU4z5s"
    }
}
*/

/*
The `jwk` you pass in the constructor is created in the following manner.
1) Create a RSA public/private key pair. E.g., I used the method here:
    https://github.com/Kitura/Swift-JWT
2) Check to make sure the public key has a first line: "-----BEGIN PUBLIC KEY-----"
3) Convert that PEM public key to a JWK. I used the python script referenced here:
    https://ruleoftech.com/2020/generating-jwt-and-jwk-for-information-exchange-between-services
    See:
        https://github.com/jpf/okta-jwks-to-pem/blob/master/pem_to_jwks.py
4) This JWK (a JSON string) is what you will use as the `jwk` parameter below.
 */

public class DPoP {
    public static let httpHeaderKey = "DPoP"
    
    enum DPoPError: Error {
        case couldNotConvertPrivateKeyToData
    }
    
    let header:Header
    let body: BodyClaims
    let privateKey: String
    
    /**
     * Parameters:
     *   jwk: Your PEM public key converted to a JWK. This is the resulting JSON.
     *      See https://datatracker.ietf.org/doc/html/rfc7517
     *   See also https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-13
     *   body: The claims for the DPoP
     *   privateKey: Your PEM private key. The first line of this starts with:
     *      -----BEGIN RSA PRIVATE KEY-----
     */
    public init(jwk: String, privateKey: String, body: BodyClaims) {
        self.header = Header(typ: "dpop+jwt", jku: nil, jwk: jwk, kid: nil, x5u: nil, x5c: nil, x5t: nil, x5tS256: nil, cty: nil, crit: nil)
        self.body = body
        self.privateKey = privateKey
    }
    
    /// Generates the signed DPoP.
    public func generate() throws -> String {
        guard let privateKey = privateKey.data(using: .utf8) else {
            throw DPoPError.couldNotConvertPrivateKeyToData
        }
        
        let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
        var jwt = JWT(header: header, claims: body)
        return try jwt.sign(using: jwtSigner)
    }
}
