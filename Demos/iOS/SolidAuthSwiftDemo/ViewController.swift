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

// Fails on registration request: https://broker.pod.inrupt.com

class ViewController: UIViewController {
    let config = SignInConfiguration(
        issuer: "https://solidcommunity.net",
        redirectURI: "biz.SpasticMuffin.Neebla.demo:/mypath",
        clientName: "Neebla",
        scopes: [.openid, .profile, .webid, .offlineAccess],
        responseTypes:  [.code /* , .token */])
    var controller: SignInController!
    var tokenRequest:TokenRequest<JWK_RSA>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                self.requestTokens(response: response)
            }
        }
    }
    
    // I'm planning to this request on the server, but it's easier for now to do a test on iOS.
    func requestTokens(response: AuthorizationResponse) {
        guard let tokenEndpoint = controller.providerConfig?.tokenEndpoint else {
            logger.error("Could not get tokenEndpoint")
            return
        }
        
        guard let codeVerifier = controller?.auth?.request.codeVerifier else {
            logger.error("Could not get codeVerifier")
            return
        }
        
        guard let code = response.authorizationCode else {
            logger.error("Could not get code")
            return
        }
        
        guard let redirectURL = controller?.auth?.request.redirectURL else {
            logger.error("Could not get redirectURL")
            return
        }
        
        guard let clientId = controller?.auth?.request.clientID else {
            logger.error("Could not get clientID")
            return
        }

        let keyPairFile = URL(fileURLWithPath: "/Users/chris/Developer/Private/SolidAuthSwiftTools/keyPair.json")
        
        guard let keyPair = try? KeyPair.loadFrom(file: keyPairFile) else {
            logger.error("Could not load KeyPair")
            return
        }
        
        let jwk: JWK_RSA
        do {
            jwk = try JSONDecoder().decode(JWK_RSA.self, from: Data(keyPair.jwk.utf8))
        } catch let error {
            logger.error("Could not decode JWK: \(error)")
            return
        }
        
        tokenRequest = TokenRequest(tokenEndpoint: tokenEndpoint, codeVerifier: codeVerifier, code: code, redirectUri: redirectURL.absoluteString, clientId: clientId, jwk: jwk, privateKey: keyPair.privateKey)
        tokenRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on TokenRequest: \(error)")
            case .success(let response):
                logger.debug("SUCCESS: On TokenRequest: \(String(describing: response.access_token))")
            }
        }
    }
}
