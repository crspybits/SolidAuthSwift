//
//  Token.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation
import SwiftJWT2
import JWTKit

// Given a token that resulted from a TokenRequest, check to see if it is valid and if it has expired.

public class Token {
    public let claims: TokenClaims
    
    // This verifies the signature of the tokenString -- and throws an error if it isn't correct.
    public init(_ tokenString: String, jwks: JWKS) throws {
        let signers = JWTSigners()
        try signers.use(jwks: jwks)
        
        self.claims = try signers.verify(tokenString, as: TokenClaims.self)
    }
    
    public enum ValidateClaimsResult {
        case expired
        case notBefore
        case issuedAt
        case success
    }
    
    // Adapted from SwiftJWT
    public func validateClaims(leeway: TimeInterval = 0) -> ValidateClaimsResult {
        let now = Date()
        
        if let expirationDate = claims.exp {
            if expirationDate + leeway < now {
                return .expired
            }
        }
        
        if let notBeforeDate = claims.nbf {
            if notBeforeDate > now + leeway {
                return .notBefore
            }
        }
        
        if let issuedAtDate = claims.iat {
            if issuedAtDate > now + leeway {
                return .issuedAt
            }
        }
        
        return .success
    }
}
