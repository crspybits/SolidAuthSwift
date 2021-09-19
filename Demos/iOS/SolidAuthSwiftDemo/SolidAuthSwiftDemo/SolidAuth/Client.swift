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
    var logoutRequest: LogoutRequest!
    static let redirect = "biz.SpasticMuffin.Neebla.demo:/mypath"
    
    private let config = SignInConfiguration(
        // These work:
        // issuer: "https://inrupt.net",
        issuer: "https://solidcommunity.net",
        //issuer: "https://broker.pod.inrupt.com",
        
        // This is failing: https://github.com/crspybits/SolidAuthSwift/issues/4
        // issuer: "https://trinpod.us",
        
        redirectURI: redirect,
        postLogoutRedirectURI: redirect,
        clientName: "Neebla",
        
        // This works with https://inrupt.net, https://solidcommunity.net, and https://broker.pod.inrupt.com
        scopes: [.openid, .profile, .webid, .offlineAccess],        
        
        // With `https://solidcommunity.net` if I use:
        //      responseTypes:  [.code, .token]
        // I get: unsupported_response_type
        
        // This works with "https://inrupt.net", and "https://solidcommunity.net",
        // responseTypes:  [.code, .idToken],

        responseTypes:  [.code],
        
        // This results in a refresh token with https://inrupt.net, https://solidcommunity.net, but not with https://broker.pod.inrupt.com
        // grantTypes: [.authorizationCode],
        
        // This results in a refresh token with https://inrupt.net, https://solidcommunity.net, and https://broker.pod.inrupt.com
        grantTypes: [.authorizationCode, .refreshToken],

        authenticationMethod: .basic
        
        // TESTING
        // authenticationMethod: .none
    )

    private var controller: SignInController!

    var accessToken: String? {
        guard let response = self.response else {
            return nil
        }

        return response.accessToken
    }

    var idToken: String? {
        guard let response = self.response else {
            return nil
        }

        return response.idToken
    }

    init() {        
        guard let controller = try? SignInController(config: config) else {
            logger.error("Could not initialize Controller")
            return
        }
        
        self.controller = controller
        self.initialized = true
    }
    
    func start(completion: @escaping (RefreshParameters?)->()) {
        controller.start() { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("Sign In Controller failed: \(error)")
                completion(nil)
                
            case .success(let response):
                logger.debug("**** Sign In Controller succeeded ****: \(response)")
                
                // Save the response locally. Just for testing. In my actual app this will involve sending the client response to my custom server.
                self.response = response
                logger.debug("Controller response: \(response)")
                
                completion(response.parameters.refresh)
            }
        }
    }
    
    func logout() {
        guard let idToken = idToken else {
            logger.error("Can't logout: No idToken")
            return
        }
        
        controller.logout(idToken: idToken) { error in
            if let error = error {
                logger.debug("Logout: Error: \(error)")
            }
            else {
                logger.debug("Logout: SUCCESS!!")
            }
        }
    }
}
