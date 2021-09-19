//
//  Authorization.swift
//
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import UIKit
import AuthenticationServices
import SolidAuthSwiftTools

// Needs to be subclass of NSObject for `ASWebAuthenticationPresentationContextProviding` conformanace.

public class Authorization: NSObject {
    enum AuthorizationError: Error {
        case flowNotStarted
        case couldNotGetParameters
        case userCanceledAuthorizationFlow
        case urlNotHandled
        case couldNotGetURLWithoutQuery
    }
    
    public let request: AuthorizationRequest
    let ephemeralSesssion: Bool
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    var completion: ((Result<AuthorizationResponse, Error>) -> Void)!
    var queue: DispatchQueue!

    /**
     * Initialize the authorization request. See https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-6
     *
     * Parameters:
     *  request: The request parameters.
     *  presentationContextProvider: If you use a nil
     *    `presentationContextProvider`, this class provides a default.
     *  ephemeralSesssion: Use this value for prefersEphemeralWebBrowserSession
     *    for the ASWebAuthenticationSession. If you use `false`, then each
     *    subsequent time (at least for short subsequent time intervals) you use
     *    `makeRequest` to have the sign in (without
     *    subsequently signing out), no actual sign in screen will be shown,
     *    unless the user signs out. See also comment [1] in code below.
     */
    public init(request: AuthorizationRequest, presentationContextProvider: ASWebAuthenticationPresentationContextProviding? = nil, ephemeralSesssion: Bool = true) {
        self.request = request
        self.presentationContextProvider = presentationContextProvider
        self.ephemeralSesssion = ephemeralSesssion
    }
    
    // Actually carry out the authorization request.
    public func makeRequest(queue: DispatchQueue = .main, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
        self.completion = completion
        self.queue = queue
        presentAuthenticationViewController()
    }
    
    func callCompletion(_ result: Result<AuthorizationResponse, Error>) {
        queue.async { [weak self] in
            self?.completion?(result)
        }
    }
    
    /*
     This only works on iOS 12+
     */
    func presentAuthenticationViewController() {
        guard let requestURL = try? request.externalUserAgentRequestURL(),
            let redirectScheme = request.redirectScheme() else {
            callCompletion(.failure(AuthorizationError.couldNotGetParameters))
            return
        }

        logger.debug("requestURL: \(requestURL)")
        
        let authenticationVC = ASWebAuthenticationSession(url: requestURL, callbackURLScheme: redirectScheme, completionHandler: { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            logger.debug("presentAuthenticationViewController: \(String(describing: callbackURL)); \(String(describing: error))")

            guard let callbackURL = callbackURL else {
                self.callCompletion(.failure(AuthorizationError.userCanceledAuthorizationFlow))
                return
            }
            
            let resumeResult: ResumeResponse
            
            do {
                resumeResult = try self.resumeExternalUserAgentFlow(callbackUrl: callbackURL)
            } catch let error {
                logger.error("ResumeExternalUserAgentFlow: \(error)")
                self.callCompletion(.failure(error))
                return
            }
            
            switch resumeResult {
            case .error(let nsError):
                self.callCompletion(.failure(nsError))
                
            case .urlNotHandled:
                // This seems like an error. Why should the URL not be handled when we gave it the one we wanted.
                self.callCompletion(.failure(AuthorizationError.urlNotHandled))
                
            case .success(let response):
                self.callCompletion(.success(response))
            }
        })

        // [1] Trying to deal with signout issue. Without setting this to `true`, after a sign in, if you try to sign in again, the username/password web UI is *not* shown. I believe this is because a cookie gets stored somewhere in iOS, and the following causes that cookie to not get set. So, second and following times you do get asked to sign in. See also https://stackoverflow.com/questions/47207914/sfauthenticationsession-aswebauthenticationsession-and-logging-out
        authenticationVC.prefersEphemeralWebBrowserSession = ephemeralSesssion
        
        authenticationVC.presentationContextProvider = presentationContextProvider ?? self
        
        if !authenticationVC.start() {
            callCompletion(.failure(AuthorizationError.flowNotStarted))
        }
    }

    enum ResumeResponse {
        case urlNotHandled
                
        case error(NSError)
        
        case success(AuthorizationResponse)
    }
    
    func resumeExternalUserAgentFlow(callbackUrl url: URL) throws -> ResumeResponse {
        guard let urlWithoutQuery = url.absoluteStringByTrimmingQuery() else {
            throw AuthorizationError.couldNotGetURLWithoutQuery
        }
        
        guard urlWithoutQuery.lowercased() == request.redirectURL.absoluteString.lowercased() else {
            return .urlNotHandled
        }

        let query = try QueryUtilities(url: url)
        query.dictionaryValue = try query.getDictionaryValue()
        
        // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
        if (query.dictionaryValue[OIDOAuthErrorFieldError] != nil) {
            return .error(ErrorUtilities.OAuthError(OAuthErrorDomain: OIDOAuthAuthorizationErrorDomain, OAuthResponse: query.dictionaryValue, underlyingError: nil))
        }
        
        // no error, should be a valid OAuth 2.0 response
        let response = AuthorizationResponse(parameters: query.dictionaryValue)

        if response.state == nil && response.additionalParameters?["state"] != nil {
            response.state = response.additionalParameters?["state"] as? String
        }
        
        if response.authorizationCode == nil && response.additionalParameters?["code"] != nil {
            response.authorizationCode = response.additionalParameters?["code"] as? String
        }
        
        if request.state != response.state {
            var userInfo = query.dictionaryValue
            if let aState = response.state {
                userInfo[NSLocalizedDescriptionKey] = """
                    State mismatch, expecting \(String(describing: request.state)) but got \(aState) in authorization \
                    response \(response)
                    """ as (NSObject & NSCopying)
            }
            
            return .error(NSError(domain: OIDOAuthAuthorizationErrorDomain, code: ErrorCodeOAuthAuthorization.ClientError.rawValue, userInfo: userInfo))
        }

        return .success(response)
    }

#if false
    func dismissAuthenticationViewController(animated: Bool, completion: @escaping () -> Void) {
        if !externalUserAgentFlowInProgress {
            // Ignore this call if there is no authorization flow in progress.
            return
        }
        
        // dismiss the ASWebAuthenticationSession
        webAuthenticationVC?.cancel()
        webAuthenticationVC = nil
        completion()
    }
    
    func failExternalUserAgentFlow(error: NSError)  {
        didFinish(with: nil, error:error)
    }
    
    /*! @brief Invokes the pending callback and performs cleanup.
     @param response The authorization response, if any to return to the callback.
     @param error The error, if any, to return to the callback.
     */
    func didFinish(with response: AuthorizationResponse?, error: NSError?)  {
        let callback = pendingauthorizationFlowCallback!
        pendingauthorizationFlowCallback = nil
//        externalUserAgent = nil
        //if callback
//        callback(response, error)
    }
#endif
}

extension Authorization: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
