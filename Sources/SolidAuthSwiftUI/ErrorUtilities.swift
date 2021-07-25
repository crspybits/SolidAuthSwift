//
//  ErrorUtilities.swift
//
//  Created by Warwick McNaughton on 26/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation

let OIDGeneralErrorDomain = "org.openid.appauth.general"
let OIDOAuthAuthorizationErrorDomain = "org.openid.appauth.oauth_authorization"
let OIDOAuthTokenErrorDomain = "org.openid.appauth.oauth_token"
let OIDOAuthRegistrationErrorDomain = "org.openid.appauth.oauth_registration"
let OIDResourceServerAuthorizationErrorDomain = "org.openid.appauth.resourceserver"
let OIDHTTPErrorDomain = "org.openid.appauth.remote-http"
let OIDOAuthErrorResponseErrorKey = "OIDOAuthErrorResponseErrorKey"
let OIDOAuthErrorFieldError = "error"
let OIDOAuthErrorFieldErrorDescription = "error_description"
let OIDOAuthErrorFieldErrorURI = "error_uri"
let OIDOAuthExceptionInvalidAuthorizationFlow = "An OAuth redirect was sent to a OIDExternalUserAgentSession after it already completed."
let OIDOAuthExceptionInvalidTokenRequestNullRedirectURL = "A OIDTokenRequest was created with a grant_type that requires a redirectURL, but a null redirectURL was given"

enum ErrorCode: Int {
    case InvalidDiscoveryDocument = -2
    case UserCanceledAuthorizationFlow = -3
    case ProgramCanceledAuthorizationFlow = -4
    case NetworkError = -5
    case ServerError = -6
    case JSONDeserializationError = -7
    case TokenResponseConstructionError = -8
    case SafariOpenError = -9
    case BrowserOpenError = -10
    case TokenRefreshError = -11
    case RegistrationResponseConstructionError = -12
    case JSONSerializationError = -13
    case IDTokenParsingError = -14
    case IDTokenFailedValidationError = -15
}

enum ErrorCodeOAuth: Int {
    case InvalidRequest = -2
    case UnauthorizedClient = -3
    case AccessDenied = -4
    case UnsupportedResponseType = -5
    case InvalidScope = -6
    case ServerError = -7
    case TemporarilyUnavailable = -8
    case InvalidClient = -9
    case InvalidGrant = -10
    case UnsupportedGrantType = -11
    case InvalidRedirectURI = -12
    case InvalidClientMetadata = -13
    case ClientError = -0xEFFF
    case Other = -0xF000
}

enum ErrorCodeOAuthAuthorization: Int {
    case InvalidRequest = -2
    case UnauthorizedClient = -3
    case AccessDenied = -4
    case UnsupportedResponseType = -5
    case InvalidScope = -6
    case ServerError = -7
    case TemporarilyUnavailable = -8
    case ClientError = -0xEFFF
    case Other = -0xF000
}


enum ErrorCodeOAuthToken: Int {
    case InvalidRequest = -2
    case InvalidClient = -9
    case InvalidGrant = -10
    case UnauthorizedClient = -3
    case UnsupportedGrantType = -11
    case InvalidScope = -6
    case ClientError = -0xEFFF
    case Other = -0xF000
}


enum ErrorCodeOAuthRegistration: Int {
    case InvalidRequest = -2
    case InvalidRedirectURI = -12
    case InvalidClientMetadata = -13
    case ClientError = -0xEFFF
    case Other = -0xF000
}


class ErrorUtilities {
    static func error(code: ErrorCode, underlyingError: NSError?, description: String?)-> NSError  {
        var userInfo = [String : Any]()
        if underlyingError != nil {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        if description != nil {
            userInfo[NSLocalizedDescriptionKey] = description
        }
        
        let error = NSError(domain: OIDGeneralErrorDomain, code: code.rawValue, userInfo: userInfo)
        return error
    }
    
    static func isOAuthErrorDomain(errorDomain: String) -> Bool {
        return errorDomain == OIDOAuthRegistrationErrorDomain
            || errorDomain == OIDOAuthAuthorizationErrorDomain
            || errorDomain == OIDOAuthTokenErrorDomain
    }
    
#if false
    static func resourceServerAuthorizationError(code: Int, errorResponse: [AnyHashable : Any]?, underlyingError: NSError?)-> NSError {
        var userInfo = [String : Any]()
        if errorResponse != nil {
            userInfo[OIDOAuthErrorResponseErrorKey] = errorResponse
        }
        if underlyingError != nil {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        let error = NSError(domain: OIDResourceServerAuthorizationErrorDomain, code: code, userInfo: userInfo)
        return error
    }
#endif
    
    static func OAuthError(OAuthErrorDomain: String, OAuthResponse errorResponse:Dictionary<String, Any>?, underlyingError: NSError?) -> NSError {
        if isOAuthErrorDomain(errorDomain: OAuthErrorDomain) == false
            || errorResponse == nil
            || errorResponse![OIDOAuthErrorFieldError] == nil
            || (errorResponse![OIDOAuthErrorFieldError] is String) == false {
            
            return ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: underlyingError,  description: underlyingError?.localizedDescription)
        }
        
        var userInfo = [String : Any]()
        userInfo[OIDOAuthErrorResponseErrorKey] = errorResponse
        if underlyingError != nil {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        let oauthErrorCodeString = errorResponse?[OIDOAuthErrorFieldError] as? String
        var oauthErrorMessage: String?
        
        if let errorResponse = errorResponse, errorResponse[OIDOAuthErrorFieldErrorDescription] is String {
            oauthErrorMessage = (errorResponse[OIDOAuthErrorFieldErrorDescription] as? String)?.description
        }
        
        var oauthErrorURI: String?
        
        if let errorResponse = errorResponse,
            let response = errorResponse[OIDOAuthErrorFieldErrorURI] {
            if response is String {
                oauthErrorURI = response as? String
            }
            else {
                oauthErrorURI = "\(response)"
            }
        }
        
        var description = ""
        description.append(oauthErrorCodeString ?? "")
        if oauthErrorMessage != nil {
            description.append(": ")
            description.append(oauthErrorMessage!)
        }
        
        if oauthErrorURI != nil {
            if description.count > 0 {
                description.append(" - ")
            }
            description.append(oauthErrorURI!)
        }
        
        if description.count == 0 {
            description.append("OAuth error: \(String(describing: oauthErrorCodeString)) - https://tools.ietf.org/html/rfc6749#section-5.2")
        }
        
        userInfo[NSLocalizedDescriptionKey] = description
        
        let code = ErrorUtilities.OAuthErrorCode(string: oauthErrorCodeString ?? "")
        let error = NSError(domain: OAuthErrorDomain, code: code.rawValue, userInfo: userInfo)
        return error
    }
    
#if false
    static func HTTPError(HTTPResponse HTTPURLResponse:HTTPURLResponse, data: Data?)-> NSError {
        var userInfo = [String : Any]()
        if data != nil {
            let serverResponse = String(data: data!, encoding: String.Encoding.utf8)
            if serverResponse != nil {
                userInfo[NSLocalizedDescriptionKey] = serverResponse
            }
        }
        let serverError = NSError(domain: OIDHTTPErrorDomain, code: HTTPURLResponse.statusCode, userInfo: userInfo)
        return serverError
    }
#endif

    static func OAuthErrorCode(string errorCode: String)-> ErrorCodeOAuth {
        let errorCodes = [
            "invalid_request": (ErrorCodeOAuth.InvalidRequest),
            "unauthorized_client": (ErrorCodeOAuth.UnauthorizedClient),
            "access_denied": (ErrorCodeOAuth.AccessDenied),
            "unsupported_response_type": (ErrorCodeOAuth.UnsupportedResponseType),
            "invalid_scope": (ErrorCodeOAuth.InvalidScope),
            "server_error": (ErrorCodeOAuth.ServerError),
            "temporarily_unavailable": (ErrorCodeOAuth.TemporarilyUnavailable),
            "invalid_client": (ErrorCodeOAuth.InvalidClient),
            "invalid_grant": (ErrorCodeOAuth.InvalidGrant),
            "unsupported_grant_type": (ErrorCodeOAuth.UnsupportedGrantType)
        ]
        
        guard let code = errorCodes[errorCode] else {
            return ErrorCodeOAuth.Other
        }
        
        return code
    }
}

