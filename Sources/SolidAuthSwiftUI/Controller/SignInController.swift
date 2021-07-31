//
//  SignInController.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
import SolidAuthSwiftTools

// The purpose of this class is to present a Pod sign in UI to the user, and to generate a `SignInController.Response`.
// After that, if in the `SignInConfiguration` you ask for a .code response type, you might pass the resulting `code` to your server to complete the flow from step 12 onwards-- see https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-12
// See also https://forum.solidproject.org/t/both-client-and-server-accessing-a-pod/4511/6

public class SignInController {
    public struct Response: Codable {
        public let authResponse: AuthorizationResponse
        public let parameters: CodeParameters
    }
    
    enum ControllerError: Error {
        case badRedirectURIString
        case noClientId
        case generateParameters(String)
    }
    
    let authConfig: AuthorizationConfiguration
    let redirectURI:URL
    let config: SignInConfiguration
    
    var request:RegistrationRequest!
    public var auth:Authorization!
    public var providerConfig: ProviderConfiguration!
    var completion: ((Result<SignInController.Response, Error>)-> Void)!
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

    /**
     *  Starts off sequence:
     *      1) Fetch configuration
     *      2) Client registration
     *      3) Authorization request
     */
    public func start(queue: DispatchQueue = .main, completion: @escaping (Result<SignInController.Response, Error>)-> Void) {
        self.completion = completion
        self.queue = queue
        fetchConfiguration()
    }
    
    func callCompletion(_ result: Result<SignInController.Response, Error>) {
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
                self.providerConfig = config
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
                logger.error("Failed client registration: \(error)")
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
                do {
                    let params = try self.prepRequestParameters(response: response)
                    let result = Response(authResponse: response, parameters: params)
                    self.callCompletion(.success(result))
                } catch let error {
                    self.callCompletion(.failure(error))
                }
            }
        }
    }
    
    func prepRequestParameters(response: AuthorizationResponse) throws -> CodeParameters {
        guard let tokenEndpoint = providerConfig?.tokenEndpoint else {
            throw ControllerError.generateParameters("Could not get tokenEndpoint")
        }
 
        guard let jwksURL = providerConfig?.jwksURL else {
            throw ControllerError.generateParameters("Could not get jwksURL")
        }
        
        guard let codeVerifier = auth?.request.codeVerifier else {
            throw ControllerError.generateParameters("Could not get codeVerifier")
        }
        
        guard let code = response.authorizationCode else {
            throw ControllerError.generateParameters("Could not get code")
        }
        
        guard let redirectURL = auth?.request.redirectURL else {
            throw ControllerError.generateParameters("Could not get redirectURL")
        }
        
        guard let clientId = auth?.request.clientID else {
            throw ControllerError.generateParameters("Could not get clientID")
        }
        
        return CodeParameters(tokenEndpoint: tokenEndpoint, jwksURL: jwksURL, codeVerifier: codeVerifier, code: code, redirectUri: redirectURL.absoluteString, clientId: clientId)
    }
}
