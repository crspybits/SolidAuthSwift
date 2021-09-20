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
    var userInfoRequest: UserInfoRequest!
    
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
        let base64 = try? params.toBase64()
        logger.debug("CodeParameters: (base64): \(String(describing: base64))")
        
        tokenRequest = TokenRequest(requestType: .code(params))
        tokenRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                assert(response.refresh_token != nil)
                self.tokenResponse = response
                
                logger.debug("SUCCESS: On TokenRequest")
                
                guard let refreshParams = response.createRefreshParameters(params: params) else {
                    logger.error("ERROR: Failed to create refresh parameters")
                    return
                }
                self.refreshParams = refreshParams
            }
        }
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
    
    func requestUserInfo(accessToken: String, configuration: ProviderConfiguration) {
        do {
            userInfoRequest = try UserInfoRequest(accessToken: accessToken, configuration: configuration)
        } catch let error {
            logger.error("Error: \(error)")
            return
        }
        
        userInfoRequest.send { result in
            switch result {
            case .success(let response):
                logger.info("Response: \(response)")
            case .failure(let error):
                logger.error("\(error)")
            }
        }
    }
}
