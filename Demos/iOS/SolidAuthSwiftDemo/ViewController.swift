//
//  ViewController.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/24/21.
//

import UIKit
import SolidAuthSwiftUI
import SolidAuthSwiftTools
import Logging

let keyPairPath = "/Users/chris/Developer/Private/SolidAuthSwiftTools/keyPair.json"

// Fails on registration request: https://broker.pod.inrupt.com

class ViewController: UIViewController {
    let config = SignInConfiguration(
        issuer: "https://solidcommunity.net",
        redirectURI: "biz.SpasticMuffin.Neebla.demo:/mypath",
        clientName: "Neebla",
        scopes: [.openid, .profile, .webid, .offlineAccess],
        responseTypes:  [.code /* , .token */])
    var controller: SignInController!
    var tokenRequest1:TokenRequest<JWK_RSA>!
    var tokenRequest2:TokenRequest<JWK_RSA>!
    var jwk: JWK_RSA!
    var keyPair: KeyPair!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyPairFile = URL(fileURLWithPath: keyPairPath)
        
        guard let keyPair = try? KeyPair.loadFrom(file: keyPairFile) else {
            logger.error("Could not load KeyPair")
            return
        }
        self.keyPair = keyPair
        
        do {
            jwk = try JSONDecoder().decode(JWK_RSA.self, from: Data(keyPair.jwk.utf8))
        } catch let error {
            logger.error("Could not decode JWK: \(error)")
            return
        }
        
        guard let controller = try? SignInController(config: config) else {
            logger.error("Could not initialize Controller")
            return
        }
        
        // Retain the controller because it does async operations.
        self.controller = controller
        
        controller.start() { result in
            switch result {
            case .failure(let error):
                logger.error("Sign In Controller failed: \(error)")
                
            case .success(let response):
                logger.debug("**** Sign In Controller succeeded ****: \(response)")
                self.requestTokens(params: response.parameters)
            }
        }
    }
    
    // I'm planning to do this request on the server: Because I don't want to have the encryption private key on the iOS client. But it's easier for now to do a test on iOS.
    func requestTokens(params:CodeParameters) {
        tokenRequest1 = TokenRequest(parameters: .code(params), jwk: jwk, privateKey: keyPair.privateKey)
        tokenRequest1.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                assert(response.refresh_token != nil)

                logger.debug("SUCCESS: On TokenRequest")
                
                guard let refreshParams = response.createRefreshParameters(tokenEndpoint: params.tokenEndpoint, clientId: params.clientId) else {
                    logger.error("ERROR: Failed to create refresh parameters")
                    return
                }
                
                self.refreshTokens(params: refreshParams)
            }
        }
    }
    
    // Again, this is just a test, and I intend it to be carried out on the server-- to refresh an expired access token.
    func refreshTokens(params: RefreshParameters) {
        tokenRequest2 = TokenRequest(parameters: .refresh(params), jwk: jwk, privateKey: keyPair.privateKey)
        tokenRequest2.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on Refresh TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                
                logger.debug("SUCCESS: On Refresh TokenRequest")
            }
        }
    }
}
