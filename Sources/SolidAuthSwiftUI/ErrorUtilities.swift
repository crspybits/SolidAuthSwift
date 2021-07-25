//
//  ErrorUtilities.swift
//  POD browser
//
//  Created by Warwick McNaughton on 26/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//

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
