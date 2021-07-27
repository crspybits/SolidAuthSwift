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
 
/*
I had a lot of problems with quoting in the header. Originally I was passing in a quoted string to these methods. But ended up passing a Codable to make it easier.
    See also https://github.com/solid/solidcommunity.net/issues/48
*/

public let DPoPHttpHeaderKey = "DPoP"

public class DPoP<JWK: JWKCommon> {
    enum DPoPError: Error {
        case couldNotConvertPrivateKeyToData
    }
    
    let header:Header<JWK>
    let body: BodyClaims
    let privateKey: String
    
    /**
     * Parameters:
     *   jwk: Your PEM public key converted to a JWK, as a Codable.
     *      See also https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-13
     *      and https://datatracker.ietf.org/doc/html/rfc7517
     *   body: The claims for the DPoP
     *   privateKey: Your PEM private key. The first line of this starts with:
     *      -----BEGIN RSA PRIVATE KEY-----
     */
    public init(jwk: JWK, privateKey: String, body: BodyClaims) {
        self.header = Header(alg: jwk.alg, typ: "dpop+jwt", jku: nil, jwk: jwk, kid: nil, x5u: nil, x5c: nil, x5t: nil, x5tS256: nil, cty: nil, crit: nil)
        self.body = body
        self.privateKey = privateKey
    }

    /// Generates the signed DPoP.
    public func generate() throws -> String {
        guard let privateKey = privateKey.data(using: .utf8) else {
            throw DPoPError.couldNotConvertPrivateKeyToData
        }
        
        let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
        
        let headerString = try header.encode()
        let claimsString = try body.encode()
        
        return try jwtSigner.sign(header: headerString, claims: claimsString)
    }
}

// Adapted from SwiftJWT
struct Header<JWK: JWKCommon>: Codable {
    
    /// Type Header Parameter
    public var typ: String?
    /// Algorithm Header Parameter
    public var alg: String?
    /// JSON Web Token Set URL Header Parameter
    public var jku : String?
    
    /// JSON Web Key Header Parameter
    public var jwk: JWK?
    
    /// Key ID Header Parameter
    public var kid: String?
    /// X.509 URL Header Parameter
    public var x5u: String?
    /// X.509 Certificate Chain Header Parameter
    public var x5c: [String]?
    /// X.509 Certificate SHA-1 Thumbprint Header Parameter
    public var x5t: String?
    /// X.509 Certificate SHA-256 Thumbprint Header Parameter
    public var x5tS256: String?
    /// Content Type Header Parameter
    public var cty: String?
    /// Critical Header Parameter
    public var crit: [String]?
    
    /// Initialize a `Header` instance.
    ///
    /// - Parameter typ: The Type Header Parameter
    /// - Parameter jku: The JSON Web Token Set URL Header Parameter
    /// - Parameter jwk: The JSON Web Key Header Parameter
    /// - Parameter kid: The Key ID Header Parameter
    /// - Parameter x5u: The X.509 URL Header Parameter
    /// - Parameter x5c: The X.509 Certificate Chain Header Parameter
    /// - Parameter x5t: The X.509 Certificate SHA-1 Thumbprint Header Parameter
    /// - Parameter x5tS256: X.509 Certificate SHA-256 Thumbprint Header Parameter
    /// - Parameter cty: The Content Type Header Parameter
    /// - Parameter crit: The Critical Header Parameter
    /// - Returns: A new instance of `Header`.
    public init(
        alg: String? = nil,
        typ: String? = "JWT",
        jku: String? = nil,
        jwk: JWK? = nil,
        kid: String? = nil,
        x5u: String? = nil,
        x5c: [String]? = nil,
        x5t: String? = nil,
        x5tS256: String? = nil,
        cty: String? = nil,
        crit: [String]? = nil
    ) {
        self.alg = alg
        self.typ = typ
        self.jku = jku
        self.jwk = jwk
        self.kid = kid
        self.x5u = x5u
        self.x5c = x5c
        self.x5t = x5t
        self.x5tS256 = x5tS256
        self.cty = cty
        self.crit = crit
    }
    
    func encode() throws -> String  {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        let data = try jsonEncoder.encode(self)
        return JWTEncoder.base64urlEncodedString(data: data)
    }
}
