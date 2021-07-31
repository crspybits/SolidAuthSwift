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
    var jwk: JWK_RSA!
    let keyPair: KeyPair = KeyPair.example
    var tokenRequest:TokenRequest<JWK_RSA>!
    @Published var refreshParams: RefreshParameters?
    var jwksRequest: JwksRequest!
    var tokenResponse: TokenResponse!
    
    init() {
        do {
            jwk = try JSONDecoder().decode(JWK_RSA.self, from: Data(keyPair.jwk.utf8))
        } catch let error {
            logger.error("Could not decode JWK: \(error)")
            return
        }    
    }
    
    // I'm planning to do this request on the server: Because I don't want to have the encryption private key on the iOS client. But it's easier for now to do a test on iOS.
    func requestTokens(params:CodeParameters) {
        tokenRequest = TokenRequest(requestType: .code(params), jwk: jwk, privateKey: keyPair.privateKey)
        tokenRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                assert(response.refresh_token != nil)
                self.tokenResponse = response
                
                logger.debug("SUCCESS: On TokenRequest")
                
                guard let refreshParams = response.createRefreshParameters(tokenEndpoint: params.tokenEndpoint, clientId: params.clientId) else {
                    logger.error("ERROR: Failed to create refresh parameters")
                    return
                }
                self.refreshParams = refreshParams
            }
        }
    }
    
    // Again, this is just a test, and I intend it to be carried out on the server-- to refresh an expired access token.
    func refreshTokens(params: RefreshParameters) {
        tokenRequest = TokenRequest(requestType: .refresh(params), jwk: jwk, privateKey: keyPair.privateKey)
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
    
    func validateAccessToken(jwksURL: URL) {
        jwksRequest = JwksRequest(jwksURL: jwksURL)
        jwksRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("JwksRequest: \(error)")
            case .success(let response):
                guard let tokenResponse = self.tokenResponse,
                    let accessTokenString = tokenResponse.access_token else {
                    logger.error("Could not get token response or access token")
                    return
                }
                
                // logger.debug("JwksRequest: \(response.jwks.keys)")
                
                let accessToken:AccessToken
                
                do {
                    accessToken = try AccessToken(jwks: response.jwks, accessToken: accessTokenString)
                } catch let error {
                    logger.error("Failed validating access token: \(error)")
                    return
                }
                
                assert(accessToken.claims.exp != nil)
                assert(accessToken.claims.iat != nil)
                
                guard accessToken.validateClaims() == .success else {
                    logger.error("Failed validating access token claims")
                    return
                }
                
                logger.debug("SUCCESS: validated access token!")
            }
        }
    }
}
