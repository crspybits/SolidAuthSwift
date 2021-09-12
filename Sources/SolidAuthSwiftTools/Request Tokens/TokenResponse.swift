//
//  TokenResponse.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation

// Some Solid servers change the refresh token every time a new access token is generated: "each time the refresh token is used, a new refresh token is emitted, and the previous one is invalidated." https://github.com/inrupt/solid-client-authn-js/issues/1285#issuecomment-823192309

/*
access_token": "eyJhbGciOiJ...": The access token we generated. The client will use this to authenticate with the server.
"expires_in": 300: Tells the client that the access token will expire in 300 seconds (5 minutes)
"token_type": "DPoP": Tells the client that the token type is DPoP
"id_token": "eyJhbGciOiJFU...": The id token we generated. The client will use this to extract information like the user’s WebId.
"refresh_token": "eyJhbGciOiJ...": The refresh token. The client will use this to get a new access token when its current one expires.
"scope": "openid profile offline_access": The scopes that were used.
 */

public class TokenResponse: Codable {
    public var access_token: String!
    public var expires_in: Int!
    public var token_type: String!
    public var id_token: String!
    public var refresh_token: String!
    public var scope: String!
}

extension TokenResponse {
    // Only for use when the TokenRequest that generated the TokenResponse used a .code
    public func createRefreshParameters(params: CodeParameters) -> RefreshParameters? {
        guard let refresh_token = refresh_token else {
            return nil
        }
        
        return RefreshParameters(tokenEndpoint: params.tokenEndpoint, refreshToken: refresh_token, clientId: params.clientId, clientSecret: params.clientSecret, authenticationMethod: params.authenticationMethod)
    }
}
