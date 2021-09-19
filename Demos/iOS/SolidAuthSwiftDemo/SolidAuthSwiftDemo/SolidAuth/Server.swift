//
//  Server.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/28/21.
//

import Foundation
import SolidAuthSwiftUI
import SolidAuthSwiftTools
import Logging

class Server: ObservableObject {
    var tokenRequest:TokenRequest<JWK_RSA>!
    @Published var refreshParams: RefreshParameters?
    var jwksRequest: JwksRequest!
    var tokenResponse: TokenResponse!
    
    init() {
    }
    
    // Just a test. I intend it to be carried out on the server-- to refresh an expired access token.
    func refreshTokens(params: RefreshParameters) {
        tokenRequest = TokenRequest(requestType: .refresh(params))
        tokenRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on Refresh TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                
                logger.debug("SUCCESS: On Refresh TokenRequest")
            }
        }
    }

    func validateToken(_ tokenString: String, jwksURL: URL) {
        jwksRequest = JwksRequest(jwksURL: jwksURL)
        jwksRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("JwksRequest: \(error)")
            case .success(let response):
                // logger.debug("JwksRequest: \(response.jwks.keys)")
                
                let token:Token
                
                do {
                    token = try Token(tokenString, jwks: response.jwks)
                } catch let error {
                    logger.error("Failed validating access token: \(error)")
                    return
                }
                
                assert(token.claims.exp != nil)
                assert(token.claims.iat != nil)
                
                logger.debug("token.claims.sub: \(String(describing: token.claims.sub))")

                guard token.validateClaims() == .success else {
                    logger.error("Failed validating access token claims")
                    return
                }
                
                logger.debug("SUCCESS: validated token!")
            }
        }
    }
}
