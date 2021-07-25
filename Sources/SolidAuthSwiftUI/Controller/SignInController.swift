//
//  SignInController.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation

public class SignInController {
    enum ControllerError: Error {
        case badRedirectURIString
    }
    
    let authConfig: AuthorizationConfiguration
    let redirectURI:URL
    let config: SignInConfiguration
    
    var request:RegistrationRequest!
    var auth:Authorization!
    
    // Retain the instance you make, before calling `start`, because this class does async operations.
    public init(config: SignInConfiguration) throws {
        guard let redirectURI = URL(string: config.redirectURI) else {
            logger.error("Error creating URL for: \(config.redirectURI)")
            throw ControllerError.badRedirectURIString
        }
        
        self.config = config
        self.redirectURI = redirectURI
        authConfig = AuthorizationConfiguration(issuer: config.issuer)
    }

    /* Starts off sequence:
        1) fetch configuration
        2) Client registration
        3) Authorization request
    */
    public func start() {
        fetchConfiguration()
    }
    
    func fetchConfiguration() {
        authConfig.fetch { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("\(error)")
                
            case .success(let config):
                self.registerClient(config: config)
            }
        }
    }
    
    func registerClient(config: ProviderConfiguration) {
        request = RegistrationRequest(configuration: config,
            redirectURIs: [redirectURI],
            clientName: self.config.clientName,
            responseTypes: [.code],
            grantTypes: ["authorization_code"],
            subjectType: nil,
            tokenEndpointAuthMethod: "client_secret_post",
            additionalParameters: nil)
        request.send { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("Failed client regisration: \(error)")
            case .success(let response):
                guard let clientID = response.clientID else {
                    logger.error("Did not get client id in client registration response")
                    return
                }
                
                self.authorizationRequest(config: config, clientID: clientID)
            }
        }
    }
    
    // This is what, if successful, shows the sign-in UI to the user.
    func authorizationRequest(config: ProviderConfiguration, clientID: String) {
        let responseType: Set<ResponseType> = [.code]

        let request:AuthorizationRequest
        do {
            request = try AuthorizationRequest(configuration: config, clientID: clientID, scopes: self.config.scopes, redirectURL: redirectURI, responseType: responseType)
        } catch let error {
            logger.error("Error creating AuthorizationRequest: \(error)")
            return
        }
        
        auth = Authorization(request: request)
        auth.makeRequest { error in
            if let error = error {
                logger.error("Authorization: \(error)")
                return
            }
        }
    }
}
