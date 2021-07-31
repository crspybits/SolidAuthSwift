//  Created by Warwick McNaughton on 18/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher Prince

import Foundation

// NSObject subclass because of `URLSessionDelegate` conformance below.

public class AuthorizationConfiguration: NSObject {
    enum AuthorizationConfigurationError: Error {
        case generic(String)
        case noDataInConfigurationResponse
        case noURLResponse
        case badStatusCode(Int)
    }
    
    let issuer: String

    /**
     * Setup to fetch the configuration from the OP.
     * Step 3 in https://solid.github.io/authentication-panel/solid-oidc-primer
     *
     * Parameters:
     *  issuer: e.g., https://solidcommunity.net, https://inrupt.net, or
     *      https://inrupt.com
     */
    public init(issuer: String) {
        self.issuer = issuer
    }
    
    /**
     * Fetch the configuration from the OP. See https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow
     *
     * Parameters:
     *  queue: The queue on which the completion handler is called.
     *      The call is done asynchronously.
     */
    public func fetch(queue: DispatchQueue = .main, completion: @escaping (Result<ProviderConfiguration, Error>)->()) {
    
        func callCompletion(_ result: Result<ProviderConfiguration, Error>) {
            queue.async {
                completion(result)
            }
        }

        guard var discoveryURL = URL(string: issuer) else {
            callCompletion(.failure(AuthorizationConfigurationError.generic("Could not create issuerURL: \(issuer)")))
            return
        }
        
        discoveryURL.appendPathComponent(".well-known/openid-configuration")
                
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: discoveryURL, completionHandler: { data, response, error in

            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(AuthorizationConfigurationError.noDataInConfigurationResponse))
                return
            }
            
            logger.debug("Received data: \(String(describing: String(data: data, encoding: .utf8)))")
            
            guard let urlResponse = response as? HTTPURLResponse else {
                callCompletion(.failure(AuthorizationConfigurationError.noURLResponse))
                return
            }
            
            logger.debug("Received url response: \(urlResponse)")
            
            guard NetworkingExtras.statusCodeOK(urlResponse.statusCode) else {
                callCompletion(.failure(AuthorizationConfigurationError.badStatusCode(urlResponse.statusCode)))
                return
            }
            
            let config: ProviderConfiguration
            
            do {
                config = try ProviderConfiguration(JSONData: data)
            } catch let error {
                callCompletion(.failure(error))
                return
            }
            
            callCompletion(.success(config))
        })
        task.resume()
    }
}

extension AuthorizationConfiguration: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    
        var urlCredential: URLCredential?
        if let serverTrust = challenge.protectionSpace.serverTrust {
            urlCredential = URLCredential(trust: serverTrust)
        }
        
        completionHandler(.useCredential, urlCredential)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logger.debug("urlSession(_:task:didReceive:completionHandler) called")
    }
}
