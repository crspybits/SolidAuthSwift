//
//  LogoutRequest.swift
//  
//
//  Created by Christopher G Prince on 9/6/21.
//

import Foundation
import AuthenticationServices

// See https://openid.net/specs/openid-connect-rpinitiated-1_0.html#RPLogout and
// https://identityserver4.readthedocs.io/en/latest/endpoints/endsession.html

// The web view is showing a request to Sign *out*. E.g. as observed here https://developer.apple.com/forums/thread/116421
// https://community.auth0.com/t/swift-login-alert-shows-up-when-you-logout/21598/22 suggests to use
// authenticationVC.prefersEphemeralWebBrowserSession = true
// But, that just causes the logout to fail.

// Same kind of discussion here: https://stackoverflow.com/questions/47207914/sfauthenticationsession-aswebauthenticationsession-and-logging-out

// NSObject subclass because of `ASWebAuthenticationPresentationContextProviding` conformance.

public class LogoutRequest: NSObject {
    enum LogoutRequestError: Error {
        case couldNotGetParameters
        case userCanceledAuthorizationFlow
        case flowNotStarted
    }
    
    let idToken: String
    let endSessionEndpoint: URL
    let config: SignInConfiguration
    let presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    let ephemeralSesssion: Bool
    var completion:((Error?) -> Void)!
    var queue: DispatchQueue!
    
    /* Parameters:
        - idToken: This can be from the AuthorizationResponse or from an explicit token request.
        - endSessionEndpoint: From the ProviderConfiguration
        - config: The SignInConfiguration; This *must* have a `postLogoutRedirectURL`.
        - presentationContextProvider: To customize the ASWebAuthenticationPresentationContextProviding if wanted.
        - ephemeralSesssion: Use the default of `true`, or the browser will prompt the user to sign *in*.
     */
    public init(idToken: String, endSessionEndpoint: URL, config: SignInConfiguration, presentationContextProvider: ASWebAuthenticationPresentationContextProviding? = nil, ephemeralSesssion: Bool = true) {
        self.idToken = idToken
        self.endSessionEndpoint = endSessionEndpoint
        self.config = config
        self.presentationContextProvider = presentationContextProvider
        self.ephemeralSesssion = ephemeralSesssion
    }
    
    /* Makes the request to sign the user out, using a `ASWebAuthenticationSession`. If successful, a view controller screen will be shown momentarily to the user. But it's not really long enough to see anything. I think this is just the Solid server sign out screen.
     */
    public func send(queue: DispatchQueue = .main, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        self.queue = queue
        presentAuthenticationViewController()
    }
    
    func callCompletion(_ result: Error?) {
        queue.async { [weak self] in
            self?.completion?(result)
        }
    }
    
    /*
     This only works on iOS 12+
     */
    func presentAuthenticationViewController() {
        guard let requestURL = try? authorizationRequestURL(),
            let redirectScheme = config.postLogoutRedirectScheme else {
            callCompletion(LogoutRequestError.couldNotGetParameters)
            return
        }
        
        let authenticationVC = ASWebAuthenticationSession(url: requestURL, callbackURLScheme: redirectScheme, completionHandler: { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                self.callCompletion(error)
                return
            }
            
            self.callCompletion(nil)
        })
        
        authenticationVC.prefersEphemeralWebBrowserSession = ephemeralSesssion

        authenticationVC.presentationContextProvider = presentationContextProvider ?? self
        
        if !authenticationVC.start() {
            callCompletion(LogoutRequestError.flowNotStarted)
        }
    }
    
    func authorizationRequestURL() throws -> URL? {
        guard let redirectURI = config.postLogoutRedirectURL?.absoluteString else {
            return nil
        }

        let query = QueryUtilities()
        query.addParameter("id_token_hint", value: idToken)
        
        // Looks like we need this so the web UI logout returns us to the app.
        query.addParameter("post_logout_redirect_uri", value: redirectURI)
        
        return try query.urlByReplacingQuery(in: endSessionEndpoint)
    }
}

extension LogoutRequest: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
