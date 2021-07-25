//
//  Authorization.swift
//
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import UIKit
import AuthenticationServices

fileprivate let kGrantTypeAuthorizationCode = "authorization_code"

// Needs to be subclass of NSObject for `ASWebAuthenticationPresentationContextProviding` conformanace.

public class Authorization: NSObject {
    enum AuthorizationError: Error {
        case flowNotStarted
        case couldNotGetParameters
    }
    
    let request: AuthorizationRequest
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    
    // If you use a nil `presentationContextProvider`, this class provides a default.
    public init(request: AuthorizationRequest, presentationContextProvider: ASWebAuthenticationPresentationContextProviding? = nil) {
        self.request = request
        self.presentationContextProvider = presentationContextProvider
    }
    
    public func makeRequest(completion: @escaping (Error?) -> Void) {
        // Presents an external user-agent which returns with an authorization response comprising the authorization code and a state parameter
        let flowStarted = presentAuthenticationViewController()  { authorizationError in

//            if authorizationResponse != nil {
//                if (authorizationRequest?.responseType == kResponseTypeCode) {
//                     Exchanges the authorization response for tokens
//                    self.fetchTokensFromTokenEndpoint(authorizationResponse: authorizationResponse) { authState, error in
//                        completion(error)
//                    }
//                }
//            }
        }
        
        guard flowStarted else {
            completion(AuthorizationError.flowNotStarted)
            return
        }
        
        completion(nil)
    }
    
    /*
     This only works on iOS 12+
     */
    private func presentAuthenticationViewController(completion: @escaping (Error?) -> Void) -> Bool {
        
        guard let requestURL = try? request.externalUserAgentRequestURL(),
            let redirectScheme = request.redirectScheme() else {
            completion(AuthorizationError.couldNotGetParameters)
            return false
        }

        logger.debug("requestURL: \(requestURL)")
        
        let authenticationVC = ASWebAuthenticationSession(url: requestURL, callbackURLScheme: redirectScheme, completionHandler: { callbackURL, error in

            logger.debug("\(String(describing: callbackURL)); \(String(describing: error))")

//            if callbackURL != nil {
//                let _ = self.resumeExternalUserAgentFlow(with: callbackURL) { response, error in
//                    completion(response, error)
//                }
//            } else {
//                let safariError: NSError? = ErrorUtilities.error(code: ErrorCode.UserCanceledAuthorizationFlow, underlyingError: error as NSError?, description: nil)
//                self.failExternalUserAgentFlow(error: safariError!)
//            }
        })

        authenticationVC.presentationContextProvider = presentationContextProvider ?? self
        
        return authenticationVC.start()

//        if !openedSafari {
// //           cleanUp()
//            let safariError: NSError? = ErrorUtilities.error(code: ErrorCode.SafariOpenError, underlyingError: nil, description: "Unable to open Safari.")
//            failExternalUserAgentFlow(error: safariError!)
//        }
    }

    // Call this from the same named method in the App Delegate.

#if false
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        // rejects URLs that don't match redirect (these may be completely unrelated to the authorization)
        //        if !shouldHandle(URL) {
        //            return false
        //        }

        
        // checks for an invalid state
//        if (pendingauthorizationFlowCallback == nil) {
//            //           NSException.raise(NSExceptionName(rawValue: OIDOAuthExceptionInvalidAuthorizationFlow), format: "%@", arguments: OIDOAuthExceptionInvalidAuthorizationFlow as CVaListPointer)
//            fatalError(OIDOAuthExceptionInvalidAuthorizationFlow)
//        }

        let query:QueryUtilities
        
        do {
            query = try QueryUtilities(url: url)
        } catch let error {
            return false
        }

        var error: NSError?
        var response: AuthorizationResponse? = nil
        query.dictionaryValue = query.getDictionaryValue()
        
        // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
        if (query.dictionaryValue[OIDOAuthErrorFieldError] != nil) {
            error = ErrorUtilities.OAuthError(OAuthErrorDomain: OIDOAuthAuthorizationErrorDomain, OAuthResponse: query.dictionaryValue, underlyingError: nil)
        }
        // no error, should be a valid OAuth 2.0 response
        if error == nil {
            response = AuthorizationResponse(request: authorizationRequest, parameters: query.dictionaryValue)
            // verifies that the state in the response matches the state in the request, or both are nil
            //if !OIDIsEqualIncludingNil(x: request!.state, y: response?.state) {
            if response?.state == nil && response?.additionalParameters!["state"] != nil { response!.state = response!.additionalParameters!["state"] as? String}
            if response?.authorizationCode == nil && response?.additionalParameters!["code"] != nil { response!.authorizationCode = response!.additionalParameters!["code"] as? String}
            if authorizationRequest!.state != response!.state {
                var userInfo = query.dictionaryValue
                if let aState = response?.state, let aResponse = response {
                    userInfo[NSLocalizedDescriptionKey] = """
                        State mismatch, expecting \(authorizationRequest!.state!) but got \(aState) in authorization \
                        response \(aResponse)
                        """ as (NSObject & NSCopying)
                }
                response = nil
                error = NSError(domain: OIDOAuthAuthorizationErrorDomain, code: ErrorCodeOAuthAuthorization.ClientError.rawValue, userInfo: userInfo)
            }
        }
        dismissAuthenticationViewController(animated: true) {
//            self.didFinish(with: response, error:error)
            callback!(response, error)
        }
        return true
    }
#endif

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
    
    
    func fetchTokensFromTokenEndpoint(authorizationResponse: AuthorizationResponse?, callback: @escaping (AuthState?, Error?) -> Void)  {
        let tokenExchangeRequest = TokenRequest(configuration: authorizationRequest!.configuration, grantType: kGrantTypeAuthorizationCode, authorizationCode: authorizationResponse!.authorizationCode, redirectURL: authorizationRequest!.redirectURL, clientID: authorizationRequest!.clientID, clientSecret: authorizationRequest!.clientSecret, scope: nil, refreshToken: nil, codeVerifier: authorizationRequest!.codeVerifier, nonce: authorizationRequest?.nonce, additionalParameters: authorizationRequest!.additionalParameters)
        let URLRequest = tokenExchangeRequest.urlRequest()
        print("URLRequest for tokens: \(tokenExchangeRequest.description(request: URLRequest)!)")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.dataTask(with: URLRequest, completionHandler: { data, response, error in
            if error != nil {
                // A network error or server error occurred.
                var errorDescription: String? = nil
                if let anURL = URLRequest.url {
                    errorDescription = "Connection error making token request to '\(anURL)': \(error?.localizedDescription ?? "")."
                }
                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error as NSError?, description: errorDescription)
                DispatchQueue.main.async(execute: {
                    callback(nil, returnedError)
                })
                return
            }
            
            let HTTPURLResponse = response as? HTTPURLResponse
            let statusCode: Int? = HTTPURLResponse?.statusCode
            
            if statusCode != 200 {
                // A server error occurred.
                let serverError = ErrorUtilities.HTTPError(HTTPResponse: HTTPURLResponse!, data: data)
                // HTTP 4xx may indicate an RFC6749 Section 5.2 error response, attempts to parse as such.
                if statusCode! >= 400 && statusCode! < 500 {
                    let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : (NSObject & NSCopying)]) as [String : (NSObject & NSCopying)]??)
                    // If the HTTP 4xx response parses as JSON and has an 'error' key, it's an OAuth error.
                    // These errors are special as they indicate a problem with the authorization grant.
                    if json?![OIDOAuthErrorFieldError] != nil {
                        let oauthError = ErrorUtilities.OAuthError( OAuthErrorDomain: OIDOAuthTokenErrorDomain, OAuthResponse: json!, underlyingError: serverError)
                        DispatchQueue.main.async(execute: {
                            callback(nil, oauthError)
                        })
                        return
                    }
                }
                
                // Status code indicates this is an error, but not an RFC6749 Section 5.2 error.
                var errorDescription: String? = nil
                if let anURL = URLRequest.url {
                    errorDescription = "Non-200 HTTP response (\(statusCode!)) making token request to '\(anURL)'."
                }
                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.ServerError, underlyingError: serverError, description: errorDescription)
                DispatchQueue.main.async(execute: {
                    callback(nil, returnedError)
                })
                return
            }
            
            var json:[String : (NSObject & NSCopying)]?
            var jsonDeserializationError: Error?
            do {
                json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : (NSObject & NSCopying)]
            //            if jsonDeserializationError != nil {
            //                // A problem occurred deserializing the response/JSON.
            //                let errorDescription = "JSON error parsing token response: \(jsonDeserializationError?.localizedDescription ?? "")"
            //                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonDeserializationError, description: errorDescription)
            //                DispatchQueue.main.async {
            //                    callback(nil, returnedError)
            //                }
            //                return
            //            }
            }
            catch {
                jsonDeserializationError = error
                let errorDescription = "JSON error parsing token response: \(jsonDeserializationError?.localizedDescription ?? "")"
                let returnedError = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonDeserializationError as NSError?, description: errorDescription)

                DispatchQueue.main.async {
                    callback(nil, returnedError)
                }
                return
            }
            
            let tokenResponse = TokenResponse(request: tokenExchangeRequest, parameters: json!)
            
                if tokenResponse == nil {
                    // A problem occurred constructing the token response from the JSON.
                    let returnedError = ErrorUtilities.error(code: ErrorCode.TokenResponseConstructionError, underlyingError: jsonDeserializationError as NSError?, description: "Token response invalid.")
                    DispatchQueue.main.async {
                        callback(nil, returnedError)
                    }
                    return
                }
            
            
            // If an ID Token is included in the response, validates the ID Token following the rules
            // in OpenID Connect Core Section 3.1.3.7 for features that AppAuth directly supports
            // (which excludes rules #1, #4, #5, #7, #8, #12, and #13). Regarding rule #6, ID Tokens
            // received by this class are received via direct communication between the Client and the Token
            // Endpoint, thus we are exercising the option to rely only on the TLS validation. AppAuth
            // has a zero dependencies policy, and verifying the JWT signature would add a dependency.
            // Users of the library are welcome to perform the JWT signature verification themselves should
            // they wish.
            if tokenResponse.idToken != nil {
            let idToken = IDToken(idTokenString: tokenResponse.idToken)
            
            if idToken == nil {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenParsingError, underlyingError: nil, description: "ID Token parsing failed")
                DispatchQueue.main.async(execute: {
                    callback(nil, invalidIDToken)
                })
                return
            }
            
            // OpenID Connect Core Section 3.1.3.7. rule #1
            // Not supported: AppAuth does not support JWT encryption.
            
            // OpenID Connect Core Section 3.1.3.7. rule #2
            // Validates that the issuer in the ID Token matches that of the discovery document.
            let issuer: URL? = tokenResponse.request!.configuration!.issuer
                if issuer != nil && !(idToken!.issuer == issuer) {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Issuer mismatch")
                DispatchQueue.main.async(execute: {
                    callback(nil, invalidIDToken)
                })
                return
            }
            
            // OpenID Connect Core Section 3.1.3.7. rule #3
            // Validates that the audience of the ID Token matches the client ID.
            let clientID = tokenResponse.request!.clientID
                if !idToken!.audience!.contains(clientID) {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Audience mismatch")
                DispatchQueue.main.async(execute: {
                    callback(nil, invalidIDToken)
                })
                return
            }
            
            // OpenID Connect Core Section 3.1.3.7. rules #4 & #5
            // Not supported.
            
            // OpenID Connect Core Section 3.1.3.7. rule #6
            // As noted above, AppAuth only supports the code flow which results in direct communication
            // of the ID Token from the Token Endpoint to the Client, and we are exercising the option to
            // use TSL server validation instead of checking the token signature. Users may additionally
            // check the token signature should they wish.
            
            // OpenID Connect Core Section 3.1.3.7. rules #7 & #8
            // Not applicable. See rule #6.
            
            // OpenID Connect Core Section 3.1.3.7. rule #9
            // Validates that the current time is before the expiry time.
                let expiresAtDifference: TimeInterval = idToken!.expiresAt!.timeIntervalSinceNow
            if expiresAtDifference < 0 {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "ID Token expired")
                DispatchQueue.main.async(execute: {
                    callback(nil, invalidIDToken)
                })
                return
            }
            // OpenID Connect Core Section 3.1.3.7. rule #10
            // Validates that the issued at time is not more than +/- 10 minutes on the current time.
                let issuedAtDifference: TimeInterval = idToken!.issuedAt!.timeIntervalSinceNow
            if abs(Float(issuedAtDifference)) > 600 {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: """
                Issued at time is more than 5 minutes before or after \
                the current time
                """)
                DispatchQueue.main.async(execute: {
                callback(nil, invalidIDToken)
                })
                return
            }
            
            // Only relevant for the authorization_code response type
            if tokenResponse.request!.grantType == kGrantTypeAuthorizationCode {
                // OpenID Connect Core Section 3.1.3.7. rule #11
                // Validates the nonce.
                let nonce = authorizationResponse!.request!.nonce
                if nonce != "" && !(idToken!.nonce == nonce) {
                    let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Nonce mismatch")
                    DispatchQueue.main.async(execute: {
                        callback(nil, invalidIDToken)
                    })
                    return
                }
            }
            // OpenID Connect Core Section 3.1.3.7. rules #12
            // ACR is not directly supported by AppAuth.
            // OpenID Connect Core Section 3.1.3.7. rules #12
            // max_age is not directly supported by AppAuth.
            
            }
            
            // Success
            DispatchQueue.main.async(execute: {
                let authState = AuthState(authorizationResponse: authorizationResponse, tokenResponse: tokenResponse)
                callback(authState, nil)
            })
        
        }).resume()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
#endif
}

#if false
extension AuthenticateWithProviderViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
#endif

extension Authorization: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
