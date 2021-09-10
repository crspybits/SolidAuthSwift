//
//  RegistrationRequest+Send.swift
//  
//  Created by Warwick McNaughton on 18/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation

extension RegistrationRequest {
    enum RegistrationRequestError: Error {
        case nilURLRequest
        case noHTTPURLResponse
        case badStatusCode(Int)
        case oAuthError(String)
        case jsonDeserialization
        case noData
    }
    
    /**
     * Dyamically get a client id. Apparently it's possible to register one statically, but haven't seen how to do that yet.
     * For ClientID's, see https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-6
     * and https://openid.net/specs/openid-connect-registration-1_0.html
     *
     * 9/9/21: Apparently static registration is just in beta: "Solid Identity Provider support for WebID-based authentication for client applications is currently not widely available. Currently, only Inrupt’s Enterprise Solid Server (ESS) supports WebID-based authentication for client applications and only as a Beta feature." (https://docs.inrupt.com/developer-tools/javascript/client-libraries/tutorial/authenticate-client/)
     *
     * Parameters:
     *  queue: The queue to use when calling the completion.
     *  completion: Return the result.
     */
    public func send(queue: DispatchQueue = .main, completion: @escaping (Result<RegistrationResponse, Error>) -> Void) {
    
        func callCompletion(_ result: Result<RegistrationResponse, Error>) {
            queue.async {
                completion(result)
            }
        }
                
        guard let request = urlRequest() else {
            callCompletion(.failure(RegistrationRequestError.nilURLRequest))
            return
        }
        
        logger.debug("URL Request: \(request)")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                callCompletion(.failure(RegistrationRequestError.noHTTPURLResponse))
                return
            }
            
            guard NetworkingExtras.statusCodeOK(response.statusCode) else {
                if response.statusCode == 400, let data = data,
                    let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : (NSObject & NSCopying)]) as [String : (NSObject & NSCopying)]??) {
                     
                    // if the HTTP 400 response parses as JSON and has an 'error' key, it's an OAuth error
                    // these errors are special as they indicate a problem with the authorization grant
                    if json?[OIDOAuthErrorFieldError] != nil {
                        callCompletion(.failure(RegistrationRequestError.oAuthError("\(String(describing: json))")))
                        return
                    }
                }
                
                callCompletion(.failure(RegistrationRequestError.badStatusCode(response.statusCode)))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(RegistrationRequestError.noData))
                return
            }
            
            var json:[String : Any]?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            }
            catch let error {
                callCompletion(.failure(error))
                return
            }
            
            guard let json = json else {
                callCompletion(.failure(RegistrationRequestError.jsonDeserialization))
                return
            }
            
            let registrationResponse = RegistrationResponse(parameters: json)
            logger.debug("Got registration response: \(registrationResponse.description())")
            callCompletion(.success(registrationResponse))
        }).resume()
    }
}

extension RegistrationRequest: URLSessionDelegate {
}
