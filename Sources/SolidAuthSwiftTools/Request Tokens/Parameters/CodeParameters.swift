//
//  CodeParameters.swift
//  
//
//  Created by Christopher G Prince on 7/26/21.
//

import Foundation

// The main parameters needed for input to a .code TokenRequest.
// The intent is that this be encoded and sent to your custom server.

public struct CodeParameters: ParametersBasics, Codable {
    public let tokenEndpoint: URL
    
    // https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
    // URL of the OP's JSON Web Key Set [JWK] document.
    public let jwksURL: URL
    
    public let codeVerifier: String
    public let code: String
    public let redirectUri: String
    public let clientId: String
    public var grantType: String {
        "authorization_code"
    }
    
    public init(tokenEndpoint: URL, jwksURL: URL, codeVerifier: String, code: String, redirectUri: String, clientId: String) {
        self.tokenEndpoint = tokenEndpoint
        self.codeVerifier = codeVerifier
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
        self.jwksURL = jwksURL
    }
}
