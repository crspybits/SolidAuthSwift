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
        
        // This should be something like "https://crspybits.trinpod.us", "https://crspybits.inrupt.net", or "https://pod.inrupt.com/crspybits".
        // Aka. host URL; see https://github.com/SyncServerII/ServerSolidAccount/issues/4
        // If this is nil (i.e., it could not be obtained here), and your app needs it, you'll need to prompt the user for it. If it is not nil, you might want to confirm the specific storage location your app plans to use with the user anyways. E.g., your app might want to use "https://pod.inrupt.com/crspybits/YourAppPath/".
        public let storageIRI: URL?
    }
    
    enum ControllerError: Error {
        case badRedirectURIString
        case noClientId
        case generateParameters(String)
    }
    
    let authConfig: AuthorizationConfiguration
    let redirectURI:URL
    var postLogoutRedirectURI:URL?
    let config: SignInConfiguration
    var getStorageIRI: GetStorageIRI!
    var request:RegistrationRequest!
    var completion: ((Result<SignInController.Response, Error>)-> Void)!
    var queue: DispatchQueue!
    var clientSecret: String!

    public var auth:Authorization!
    public var providerConfig: ProviderConfiguration!

    // Retain the instance you make, before calling `start`, because this class does async operations.
    public init(config: SignInConfiguration) throws {
        guard let redirectURI = URL(string: config.redirectURI) else {
            logger.error("Error creating URL for: \(config.redirectURI)")
            throw ControllerError.badRedirectURIString
        }
        
        if let postLogoutRedirectURI = config.postLogoutRedirectURI {
            guard let postLogoutRedirectURI = URL(string: postLogoutRedirectURI) else {
                logger.error("Error creating URL for: \(String(describing: config.postLogoutRedirectURI))")
                throw ControllerError.badRedirectURIString
            }
            
            self.postLogoutRedirectURI = postLogoutRedirectURI
        }
        
        self.config = config
        self.redirectURI = redirectURI
        authConfig = AuthorizationConfiguration(issuer: config.issuer)
    }

    /**
     *  Starts off sequence:
     *      1) Discovery: Fetch configuration
     *      2) Client registration
     *      3) Authorization request
     *      4) Attempt to get storage IRI
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
        var postLogoutRedirectURIs: [URL]?
        if let postLogoutRedirectURI = postLogoutRedirectURI {
            postLogoutRedirectURIs = [postLogoutRedirectURI]
        }
        
        request = RegistrationRequest(configuration: config,
            redirectURIs: [redirectURI],
            postLogoutRedirectURIs: postLogoutRedirectURIs,
            clientName: self.config.clientName,
            responseTypes: self.config.responseTypes,
            grantTypes: ["authorization_code"],
            subjectType: nil,
            tokenEndpointAuthMethod: self.config.authenticationMethod,
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
                
                self.clientSecret = response.clientSecret

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
                    try self.getStorageIRI(response: response)
                } catch let error {
                    self.callCompletion(.failure(error))
                }
            }
        }
    }
    
    // On success, this will do the `callCompletion`, but not on a throw
    func getStorageIRI(response: AuthorizationResponse) throws {
        func returnEarly() throws {
            let params = try self.prepRequestParameters(response: response)
            let result = Response(authResponse: response, parameters: params, storageIRI: nil)
            self.callCompletion(.success(result))
        }
        
        guard let idToken = response.idToken else {
            try returnEarly()
            return
        }

        // This doesn't check the signature of the id token; just want to pull out the webid early.
        let token = try Token(idToken)
        
        // I'm getting a nil webid in the id token in token.claims.webid, so using token.claims.sub instead.
        guard let webid = token.claims.sub else {
            try returnEarly()
            return
        }
        
        guard let webidURL = URL(string: webid) else {
            try returnEarly()
            return
        }

        getStorageIRI = GetStorageIRI(webid: webidURL)
        getStorageIRI.get { result in
            switch result {
            case .success(let url):
                do {
                    let params = try self.prepRequestParameters(response: response)
                    let result = Response(authResponse: response, parameters: params, storageIRI: url)
                    self.callCompletion(.success(result))
                } catch let error {
                    self.callCompletion(.failure(error))
                }
            case .failure(let error):
                self.callCompletion(.failure(error))
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
        
        guard let clientSecret = clientSecret else {
            throw ControllerError.generateParameters("Could not get clientSecret")
        }

        return CodeParameters(tokenEndpoint: tokenEndpoint, jwksURL: jwksURL, codeVerifier: codeVerifier, code: code, redirectUri: redirectURL.absoluteString, clientId: clientId, clientSecret: clientSecret, authenticationMethod: config.authenticationMethod)
    }
}
