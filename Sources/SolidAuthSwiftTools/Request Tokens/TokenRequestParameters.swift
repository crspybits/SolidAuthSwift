//
//  TokenRequestParameters.swift
//  
//
//  Created by Christopher G Prince on 7/26/21.
//

import Foundation

public struct TokenRequestParameters: Codable {
    public let tokenEndpoint: URL
    
    public let codeVerifier: String
    public let code: String
    public let redirectUri: String
    public let clientId: String
    
    public init(tokenEndpoint: URL, codeVerifier: String, code: String, redirectUri: String, clientId: String) {
        self.tokenEndpoint = tokenEndpoint
        self.codeVerifier = codeVerifier
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
    }
}
