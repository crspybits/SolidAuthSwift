# SolidAuthSwift

Implements the sign-in flow as in https://solid.github.io/authentication-panel/solid-oidc-primer.

Some discussion on the [Solid Project forum](https://forum.solidproject.org/t/both-client-and-server-accessing-a-pod/4511/6).

See also https://datatracker.ietf.org/doc/html/draft-ietf-oauth-dpop-03

## Tested
With issuers:

1) https://inrupt.net

2)  https://solidcommunity.net

## SolidAuthSwiftUI

Based off https://github.com/wrmack/Get-tokens

This is intended to be used on iOS. It provides the initial sign in via web browser user interface, allowing the user to enter their credentials. The output is a `code` value (see `AuthorizationResponse`), which can then be used to generate access and refresh tokens.

### Usage example (see SolidAuthDemoApp)

```
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
        issuer: "https://inrupt.net",
        // issuer: "https://solidcommunity.net",
        // issuer: "https://broker.pod.inrupt.com",
        
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
    )

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
    
    func logout() {
        guard let idToken = response?.authResponse.idToken else {
            logger.error("Can't logout: No idToken")
            return
        }
        
        guard let endSessionEndpoint = controller.providerConfig.endSessionEndpoint else {
            logger.error("Can't logout: No endSessionEndpoint")
            return
        }
        
        logoutRequest = LogoutRequest(idToken: idToken, endSessionEndpoint: endSessionEndpoint, config: config)
        logoutRequest.send { error in
            if let error = error {
                logger.error("Failed logout: \(error)")
                return
            }
            logger.debug("Logout: SUCCESS!!")
        }
    }
}
```

### Issues or questions
#### Sometimes when you tap on the initial sign in screen prompt, you don't get any secondary prompt.
i.e., you don't get any prompt beyond [this initial one](./Docs/README/InitialPrompt.png).
I thought originally this was to do with the requested response type, but it seems independent of that.
Note that I *am* successfully getting a `AuthorizationResponse` in this case despite the lack of a seond prompt.

#### With some issuers, not getting app name showing up on sign in screen.
Despite having added "client_name" to the registration request, I'm still seeing [this](./Docs/README/AuthorizeNull.png).

### To be implemented
#### Not all codable classes are implemented or implemented in full. Mostly seems to be a style thing at this point.

## SolidAuthSwiftTools

I had originally intended this to be used only from a custom server. It is separated out from the `SolidAuthSwiftUI` library because `SolidAuthSwiftUI` contains UIKit code, and will *not* work on Linux.

Also I had thought there was a security issue, that a private/public keypair (needed to generate DPoP tokens) could not securely be stored on the iOS client. [However, if the keypair is generated on the client, that doesn't seem true!](https://github.com/crspybits/SolidAuthSwift/issues/2). Thanks @wrmack for pointing this out.

(The terminology below still reads "Server", reflecting my main use case; I just need to edit this another day).

### Usage example (see SolidAuthDemoApp)

```
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
        
        tokenRequest = TokenRequest(requestType: .code(params), jwk: jwk, privateKey: keyPair.privateKey)
        tokenRequest.send { result in
            switch result {
            case .failure(let error):
                logger.error("Failed on TokenRequest: \(error)")
            case .success(let response):
                assert(response.access_token != nil)
                assert(response.refresh_token != nil)
                self.tokenResponse = response
                
                logger.debug("SUCCESS: On TokenRequest")
                
                guard let refreshParams = response.createRefreshParameters(tokenEndpoint: params.tokenEndpoint, clientId: params.clientId) else {
                    logger.error("ERROR: Failed to create refresh parameters")
                    return
                }
                self.refreshParams = refreshParams
            }
        }
    }
    
    // Again, this is just a test, and I intend it to be carried out on the server-- to refresh an expired access token.
    func refreshTokens(params: RefreshParameters) {
        tokenRequest = TokenRequest(requestType: .refresh(params), jwk: jwk, privateKey: keyPair.privateKey)
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
    
    var accessToken: String? {
        guard let tokenResponse = self.tokenResponse,
            let accessToken = tokenResponse.access_token else {
            return nil
        }
        
        return accessToken
    }
    
    var idToken: String? {
        guard let tokenResponse = self.tokenResponse,
            let idToken = tokenResponse.id_token else {
            return nil
        }
        
        return idToken
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
}
```
