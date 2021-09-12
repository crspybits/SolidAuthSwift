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
    
    public let clientSecret: String
    public let authenticationMethod: TokenEndpointAuthenticationMethod
    
    // CodingKeys because I want to use this enum elsewhere.
    public enum CodingKeys: String, CodingKey {
        case tokenEndpoint
        case jwksURL
        case codeVerifier
        case code
        case redirectUri
        case clientId
        case clientSecret
        case authenticationMethod
    }
    
    public var grantType: String {
        "authorization_code"
    }
    
    public init(tokenEndpoint: URL, jwksURL: URL, codeVerifier: String, code: String, redirectUri: String, clientId: String, clientSecret: String, authenticationMethod: TokenEndpointAuthenticationMethod) {
        self.tokenEndpoint = tokenEndpoint
        self.codeVerifier = codeVerifier
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
        self.jwksURL = jwksURL
        self.clientSecret = clientSecret
        self.authenticationMethod = authenticationMethod
    }
}

public extension CodeParameters {
    static func from(fromBase64 base64: String) throws -> CodeParameters {
        enum FromError: Error {
            case cannotDecodeBase64
        }
        
        guard let codeParametersData = Data(base64Encoded: base64) else {
            throw FromError.cannotDecodeBase64
        }

        return try JSONDecoder().decode(CodeParameters.self, from: codeParametersData)
    }
    
    func toBase64() throws -> String {
        let serverData = try JSONEncoder().encode(self)
        return serverData.base64EncodedString()
    }
}
