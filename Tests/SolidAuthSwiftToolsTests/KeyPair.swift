//
//  KeyPair.swift
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation

public class KeyPair: Codable {
    public let publicKey: String
    public let privateKey: String
    
    // This is the public PEM key converted to a JWK. See DPoP.swift comments.
    public let jwk: String
    
    public init(publicKey: String, privateKey: String, jwk: String) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.jwk = jwk
    }
}
