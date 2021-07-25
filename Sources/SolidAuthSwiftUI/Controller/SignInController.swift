//
//  SignInController.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation

// The purpose of this class is to present a Pod sign in UI to the user, and to generate a `AuthorizationResponse`.
// After that, if in the `SignInConfiguration` you ask for a .code response type, you might pass the resulting `code` to your server to complete the flow from step 12 onwards-- see https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-12
// See also https://forum.solidproject.org/t/both-client-and-server-accessing-a-pod/4511/6

public class SignInController {
    enum ControllerError: Error {
        case badRedirectURIString
        case noClientId
    }
    
    let authConfig: AuthorizationConfiguration
    let redirectURI:URL
    let config: SignInConfiguration
    
    var request:RegistrationRequest!
    var auth:Authorization!
    var completion: ((Result<AuthorizationResponse, Error>)-> Void)!
    var queue: DispatchQueue!
    
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
    public func start(queue: DispatchQueue = .main, completion: @escaping (Result<AuthorizationResponse, Error>)-> Void) {
        self.completion = completion
        self.queue = queue
        fetchConfiguration()
    }
    
    func callCompletion(_ result: Result<AuthorizationResponse, Error>) {
        queue.async { [weak self] in
            self?.completion(result)
        }
    }
    
    func fetchConfiguration() {
        authConfig.fetch(queue: queue) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("\(error)")
                self.callCompletion(.failure(error))
                
            case .success(let config):
                self.registerClient(config: config)
            }
        }
    }
    
    func registerClient(config: ProviderConfiguration) {
        request = RegistrationRequest(configuration: config,
            redirectURIs: [redirectURI],
            clientName: self.config.clientName,
            responseTypes: self.config.responseTypes,
            grantTypes: ["authorization_code"],
            subjectType: nil,
            tokenEndpointAuthMethod: "client_secret_post",
            additionalParameters: nil)
        request.send(queue: queue) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("Failed client regisration: \(error)")
                self.callCompletion(.failure(error))
                
            case .success(let response):
                guard let clientID = response.clientID else {
                    logger.error("Did not get client id in client registration response")
                    self.callCompletion(.failure(ControllerError.noClientId))
                    return
                }
                
                self.authorizationRequest(config: config, clientID: clientID)
            }
        }
    }
    
    // This is what, if successful, shows the sign-in UI to the user.
    func authorizationRequest(config: ProviderConfiguration, clientID: String) {
        let responseType: Set<ResponseType> = self.config.responseTypes

        let request:AuthorizationRequest
        do {
            request = try AuthorizationRequest(configuration: config, clientID: clientID, scopes: self.config.scopes, redirectURL: redirectURI, responseType: responseType)
        } catch let error {
            logger.error("Error creating AuthorizationRequest: \(error)")
            self.callCompletion(.failure(error))
            return
        }
        
        auth = Authorization(request: request, presentationContextProvider: self.config.presentationContextProvider)
        auth.makeRequest(queue: queue) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                logger.error("Authorization: \(error)")
                self.callCompletion(.failure(error))
                
            case .success(let response):
                self.callCompletion(.success(response))
            }
        }
    }
}
