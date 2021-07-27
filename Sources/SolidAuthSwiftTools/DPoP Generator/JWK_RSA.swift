//
//  JWK_RSA.swift
//  
//
//  Created by Christopher G Prince on 7/26/21.
//

import Foundation

// See https://datatracker.ietf.org/doc/html/rfc7517#appendix-A.1
public struct JWK_RSA: JWKCommon {
    public let kty: String
    public let kid: String
    public let use: String
    public let alg: String
    public let n: String
    public let e: String
}
