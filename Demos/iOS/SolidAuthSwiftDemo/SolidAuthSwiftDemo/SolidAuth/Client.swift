//
//  Client.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/28/21.
//

import Foundation
import SolidAuthSwiftUI
import SolidAuthSwiftTools
import Logging

class Client: ObservableObject {
    @Published var response: SignInController.Response?
    @Published var initialized: Bool = false
    
    private let config = SignInConfiguration(
        // These work:
        // issuer: "https://inrupt.net",
        // issuer: "https://solidcommunity.net",
        
        // issuer: "https://pod.inrupt.com", // This fails with a 401
        
        // This is failing too: https://github.com/crspybits/SolidAuthSwift/issues/3
        // issuer: "https://broker.pod.inrupt.com",
        
        // This is failing: https://github.com/crspybits/SolidAuthSwift/issues/4
        issuer: "https://crspybits.trinpod.us",
        
        redirectURI: "biz.SpasticMuffin.Neebla.demo:/mypath",
        clientName: "Neebla",
        scopes: [.openid, .profile, .webid, .offlineAccess],
        
        // With `https://solidcommunity.net` if I use:
        //      responseTypes:  [.code, .token]
        // I get: unsupported_response_type
        responseTypes:  [.code, .idToken])
    private var controller: SignInController!
    
    init() {
        guard let controller = try? SignInController(config: config) else {
            logger.error("Could not initialize Controller")
            return
        }
        
        self.controller = controller
        self.initialized = true
    }
    
    func start() {
        controller.start() { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("Sign In Controller failed: \(error)")
                
            case .success(let response):
                logger.debug("**** Sign In Controller succeeded ****: \(response)")
                
                // Save the response locally. Just for testing. In my actual app this will involve sending the client response to my custom server.
                self.response = response
                logger.debug("Controller response: \(response)")
            }
        }
    }
}
