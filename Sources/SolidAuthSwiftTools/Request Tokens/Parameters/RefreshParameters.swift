//
//  RefreshParameters.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation

public struct RefreshParameters: ParametersBasics {
    public let tokenEndpoint: URL
    public let refreshToken: String
    public let clientId: String
    public var grantType: String {
        "refresh_token"
    }

    public init(tokenEndpoint: URL, refreshToken: String, clientId: String) {
        self.tokenEndpoint = tokenEndpoint
        self.refreshToken = refreshToken
        self.clientId = clientId
    }
}
