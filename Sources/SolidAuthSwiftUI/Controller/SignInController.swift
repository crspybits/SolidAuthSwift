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
        public let parameters: ServerParameters
        public let idToken: String
        public let accessToken: String
    }
    
    enum ControllerError: Error {
        case badRedirectURIString
        case noClientId
        case generateParameters(String)
        case noTokens
        case noAuthorizationResponse
        case noJwksURL
        case noWebId
    }
    
    let authConfig: AuthorizationConfiguration
    let redirectURI:URL
    var postLogoutRedirectURI:URL?
    let config: SignInConfiguration
    var getStorageIRI: GetStorageIRI!
    var request:RegistrationRequest!
    var tokenRequest:TokenRequest<JWK_RSA>!
    var authorizationResponse:AuthorizationResponse!
    var completion: ((Result<SignInController.Response, Error>)-> Void)!
    var queue: DispatchQueue!
    var clientSecret: String!
    var logoutRequest:LogoutRequest!

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
     *      4) Get refresh token and id token
     *      5) Get the users webid
     *      6) Attempt to get storage IRI
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
            grantTypes: self.config.grantTypes,
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
                self.authorizationResponse = response
                do {
                    let params = try self.prepRequestParameters(response: response)
                    self.requestTokens(params:params)
                } catch let error {
                    self.callCompletion(.failure(error))
                }
            }
        }
    }
    
    struct StorageIRIParameters {
        let authorizationResponse: AuthorizationResponse
        let idToken: String
        let accessToken: String
        let refreshParameters: RefreshParameters
    }
    
    // Get refresh token and an id token.
    func requestTokens(params:CodeParameters) {
        tokenRequest = TokenRequest(requestType: .code(params))
        tokenRequest.send { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.callCompletion(.failure(error))

            case .success(let response):
                guard let idToken = response.id_token,
                    let accessToken = response.access_token,
                    let refreshParameters = response.createRefreshParameters(params: params) else {
                    self.callCompletion(.failure(ControllerError.noTokens))
                    return
                }
                
                guard let authorizationResponse = self.authorizationResponse else {
                    self.callCompletion(.failure(ControllerError.noTokens))
                    return
                }
                
                let parameters = StorageIRIParameters(authorizationResponse: authorizationResponse, idToken: idToken, accessToken: accessToken, refreshParameters: refreshParameters)
                self.getWebId(parameters:parameters)
            }
        }
    }
    
    func getWebId(parameters:StorageIRIParameters) {
        let token: Token
        do {
            // This doesn't check the signature of the id token; just want to pull out the webid early.
            token = try Token(parameters.idToken)
        } catch let error {
            callCompletion(.failure(error))
            return
        }
        
        // For method of obtaining a webid, see https://github.com/crspybits/SolidAuthSwift/issues/7
        guard let webid = token.claims.webid ?? token.claims.sub,
            let webidURL = URL(string: webid) else {
            
            // I'd like to make a user info request as a fallback, but that's not behaving the way I'd like. See UserInfoRequest.swift.
            callCompletion(.failure(ControllerError.noWebId))
            return
        }
        
        logger.debug("token.claims.sub: \(String(describing: token.claims.sub))")
        logger.debug("token.claims.webid: \(String(describing: token.claims.webid))")
        
        getStorageIRI(webidURL: webidURL, parameters: parameters)
    }

    func getStorageIRI(webidURL: URL, parameters:StorageIRIParameters) {
        guard let jwksURL = providerConfig?.jwksURL else {
            callCompletion(.failure(ControllerError.noJwksURL))
            return
        }
        
        func returnEarly() {
            let serverParameters = ServerParameters(refresh: parameters.refreshParameters, storageIRI: nil, jwksURL: jwksURL, webid: webidURL.absoluteString, accessToken: parameters.accessToken)
            let result = Response(authResponse: parameters.authorizationResponse, parameters: serverParameters, idToken: parameters.idToken, accessToken: parameters.accessToken)
            callCompletion(.success(result))
        }

        getStorageIRI = GetStorageIRI(webid: webidURL)
        getStorageIRI.get { result in
            switch result {
            case .success(let url):
                let serverParameters = ServerParameters(refresh: parameters.refreshParameters, storageIRI: url, jwksURL: jwksURL, webid: webidURL.absoluteString, accessToken: parameters.accessToken)
                let result = Response(authResponse: parameters.authorizationResponse, parameters: serverParameters, idToken: parameters.idToken, accessToken: parameters.accessToken)
                self.callCompletion(.success(result))

            case .failure(let error):
                self.callCompletion(.failure(error))
            }
        }
    }
    
    func prepRequestParameters(response: AuthorizationResponse) throws -> CodeParameters {
        guard let tokenEndpoint = providerConfig?.tokenEndpoint else {
            throw ControllerError.generateParameters("Could not get tokenEndpoint")
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

        return CodeParameters(tokenEndpoint: tokenEndpoint, codeVerifier: codeVerifier, code: code, redirectUri: redirectURL.absoluteString, clientId: clientId, clientSecret: clientSecret, authenticationMethod: config.authenticationMethod)
    }
}
