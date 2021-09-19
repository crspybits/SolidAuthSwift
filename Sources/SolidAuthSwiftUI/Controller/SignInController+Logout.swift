//
//  SignInController+Logout.swift
//  
//
//  Created by Christopher G Prince on 9/18/21.
//

import Foundation

extension SignInController {
    enum LogoutError: Error {
        case noEndSessionEndpoint
    }
    
    public func logout(idToken: String, completion: @escaping (Error?)->()) {
        guard let endSessionEndpoint = providerConfig.endSessionEndpoint else {
            completion(LogoutError.noEndSessionEndpoint)
            return
        }
        
        logoutRequest = LogoutRequest(idToken: idToken, endSessionEndpoint: endSessionEndpoint, config: config)
        logoutRequest.send { error in
            if let error = error {
                completion(error)
                return
            }

            completion(nil)
        }
    }
}
