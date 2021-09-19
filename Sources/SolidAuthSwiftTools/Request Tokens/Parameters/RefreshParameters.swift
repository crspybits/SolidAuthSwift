//
//  RefreshParameters.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation

public struct RefreshParameters: ParametersBasics, Codable {
    public let tokenEndpoint: URL
    public let refreshToken: String
    public let clientId: String
    public let clientSecret: String
    public let authenticationMethod: TokenEndpointAuthenticationMethod

    public var grantType: String {
        GrantType.refreshToken.rawValue
    }

    public init(tokenEndpoint: URL, refreshToken: String, clientId: String, clientSecret: String, authenticationMethod: TokenEndpointAuthenticationMethod) {
        self.tokenEndpoint = tokenEndpoint
        self.refreshToken = refreshToken
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.authenticationMethod = authenticationMethod
    }
}
