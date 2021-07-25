//
//  ProviderConfiguration.swift
//  
//  Created by Warwick McNaughton on 18/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher Prince

import Foundation

/*! Field keys associated with an OpenID Connect Discovery Document. */
fileprivate let kIssuerKey = "issuer"
fileprivate let kAuthorizationEndpointKey = "authorization_endpoint"
fileprivate let kTokenEndpointKey = "token_endpoint"
fileprivate let kUserinfoEndpointKey = "userinfo_endpoint"
fileprivate let kJWKSURLKey = "jwks_uri"
fileprivate let kRegistrationEndpointKey = "registration_endpoint"
fileprivate let kScopesSupportedKey = "scopes_supported"
fileprivate let kResponseTypesSupportedKey = "response_types_supported"
fileprivate let kResponseModesSupportedKey = "response_modes_supported"
fileprivate let kGrantTypesSupportedKey = "grant_types_supported"
fileprivate let kACRValuesSupportedKey = "acr_values_supported"
fileprivate let kSubjectTypesSupportedKey = "subject_types_supported"
fileprivate let kIDTokenSigningAlgorithmValuesSupportedKey = "id_token_signing_alg_values_supported"
fileprivate let kIDTokenEncryptionAlgorithmValuesSupportedKey = "id_token_encryption_alg_values_supported"
fileprivate let kIDTokenEncryptionEncodingValuesSupportedKey = "id_token_encryption_enc_values_supported"
fileprivate let kUserinfoSigningAlgorithmValuesSupportedKey = "userinfo_signing_alg_values_supported"
fileprivate let kUserinfoEncryptionAlgorithmValuesSupportedKey = "userinfo_encryption_alg_values_supported"
fileprivate let kUserinfoEncryptionEncodingValuesSupportedKey = "userinfo_encryption_enc_values_supported"
fileprivate let kRequestObjectSigningAlgorithmValuesSupportedKey = "request_object_signing_alg_values_supported"
fileprivate let kRequestObjectEncryptionAlgorithmValuesSupportedKey = "request_object_encryption_alg_values_supported"
fileprivate let kRequestObjectEncryptionEncodingValuesSupported = "request_object_encryption_enc_values_supported"
fileprivate let kTokenEndpointAuthMethodsSupportedKey = "token_endpoint_auth_methods_supported"
fileprivate let kTokenEndpointAuthSigningAlgorithmValuesSupportedKey = "token_endpoint_auth_signing_alg_values_supported"
fileprivate let kDisplayValuesSupportedKey = "display_values_supported"
fileprivate let kClaimTypesSupportedKey = "claim_types_supported"
fileprivate let kClaimsSupportedKey = "claims_supported"
fileprivate let kServiceDocumentationKey = "service_documentation"
fileprivate let kClaimsLocalesSupportedKey = "claims_locales_supported"
fileprivate let kUILocalesSupportedKey = "ui_locales_supported"
fileprivate let kClaimsParameterSupportedKey = "claims_parameter_supported"
fileprivate let kRequestParameterSupportedKey = "request_parameter_supported"
fileprivate let kRequestURIParameterSupportedKey = "request_uri_parameter_supported"
fileprivate let kRequireRequestURIRegistrationKey = "require_request_uri_registration"
fileprivate let kOPPolicyURIKey = "op_policy_uri"
fileprivate let kOPTosURIKey = "op_tos_uri"

public class ProviderConfiguration: NSObject, Codable {
    enum ProviderConfigurationError: Error {
        case couldNotGetJSONData
        case couldNotConvertJSONData
        case missingField(String)
        case couldNotConvertURLField(String)
    }
    
    // MARK: - Properties
    
    public var discoveryDictionary: [String : Any]?
    public var authorizationEndpoint: URL?
    public var tokenEndpoint: URL?
    public var issuer: URL?
    public var registrationEndpoint: URL?
    public var discoveryDocument: ProviderConfiguration?

    private func getFromDiscoveryDictionary<T>(key: String) -> T? {
        guard let discoveryDictionary = discoveryDictionary else {
            return nil
        }
        return discoveryDictionary[key] as? T
    }

    private func getURLFromDiscoveryDictionary(key: String) -> URL? {
        guard let discoveryDictionary = discoveryDictionary,
            let value = discoveryDictionary[key] as? String else {
            return nil
        }
        return URL(string: value)
    }
    
    public var userinfoEndpoint: URL? {
        return getURLFromDiscoveryDictionary(key: kUserinfoEndpointKey)
    }
    
    public var jwksURL: URL? {
        return getURLFromDiscoveryDictionary(key: kJWKSURLKey)
    }
    
    public var scopesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kScopesSupportedKey)
    }
    
    public var responseTypesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kResponseTypesSupportedKey)
    }
    
    public var responseModesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kResponseModesSupportedKey)
    }
    
    public var grantTypesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kGrantTypesSupportedKey)
    }
    
    public var acrValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kACRValuesSupportedKey)
    }
    
    public var subjectTypesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kSubjectTypesSupportedKey)
    }
    
    public var IDTokenSigningAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kIDTokenSigningAlgorithmValuesSupportedKey)
    }
    
    public var IDTokenEncryptionAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kIDTokenEncryptionAlgorithmValuesSupportedKey)
    }
    
    public var IDTokenEncryptionEncodingValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kIDTokenEncryptionAlgorithmValuesSupportedKey)
    }
    
    public var userinfoSigningAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kUserinfoSigningAlgorithmValuesSupportedKey)
    }
    
    public var userinfoEncryptionAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kUserinfoEncryptionAlgorithmValuesSupportedKey)
    }
    
    public var userinfoEncryptionEncodingValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kUserinfoEncryptionEncodingValuesSupportedKey)
    }
    
    public var requestObjectSigningAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kRequestObjectSigningAlgorithmValuesSupportedKey)
    }
    
    public var requestObjectEncryptionAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kRequestObjectEncryptionAlgorithmValuesSupportedKey)
    }
    
    public var requestObjectEncryptionEncodingValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kRequestObjectEncryptionEncodingValuesSupported)
    }
    
    public var tokenEndpointAuthMethodsSupported: [String]? {
        return getFromDiscoveryDictionary(key: kTokenEndpointAuthMethodsSupportedKey)
    }
    
    public var tokenEndpointAuthSigningAlgorithmValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kTokenEndpointAuthSigningAlgorithmValuesSupportedKey)
    }
    
    public var displayValuesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kDisplayValuesSupportedKey)
    }
    
    public var claimTypesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kClaimTypesSupportedKey)
    }
    
    public var claimsSupported: [String]? {
        return getFromDiscoveryDictionary(key: kClaimsSupportedKey)
    }
    
    public var serviceDocumentation: URL? {
        return getFromDiscoveryDictionary(key: kServiceDocumentationKey)
    }
    
    public var claimsLocalesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kClaimsLocalesSupportedKey)
    }
    
    public var UILocalesSupported: [String]? {
        return getFromDiscoveryDictionary(key: kUILocalesSupportedKey)
    }
    
    public var claimsParameterSupported: Bool? {
        return getFromDiscoveryDictionary(key: kClaimsParameterSupportedKey)
    }
    
    public var requestParameterSupported: Bool? {
        return getFromDiscoveryDictionary(key: kRequestParameterSupportedKey)
    }
    
    public var requestURIParameterSupported: Bool {
        return getFromDiscoveryDictionary(key: kRequestURIParameterSupportedKey) ?? true
    }
    
    public var requireRequestURIRegistration: Bool? {
        return getFromDiscoveryDictionary(key: kRequireRequestURIRegistrationKey)
    }
    
    public var OPPolicyURI: URL? {
        return getURLFromDiscoveryDictionary(key: kOPPolicyURIKey)
    }
    
    public var OPTosURI: URL? {
        return getURLFromDiscoveryDictionary(key: kOPTosURIKey)
    }
    
    // MARK: - Object lifecycle
    
    public convenience init(JSON: String) throws {
        guard let jsonData = JSON.data(using: .utf8) else {
            throw ProviderConfigurationError.couldNotGetJSONData
        }
        try self.init(JSONData: jsonData)
    }
    
    public convenience init(JSONData: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? [String : Any] else {
            throw ProviderConfigurationError.couldNotConvertJSONData
        }

        try self.init(serviceDiscoveryDictionary: json)
    }
    
    public convenience init(serviceDiscoveryDictionary: [String : Any]) throws {
        self.init()
        try Self.dictionaryHasRequiredFields(dictionary: serviceDiscoveryDictionary)
        
        discoveryDictionary = serviceDiscoveryDictionary
        authorizationEndpoint = getURLFromDiscoveryDictionary(key: kAuthorizationEndpointKey)
        tokenEndpoint = getURLFromDiscoveryDictionary(key: kTokenEndpointKey)
        issuer = getURLFromDiscoveryDictionary(key: kIssuerKey)
        registrationEndpoint = getURLFromDiscoveryDictionary(key: kRegistrationEndpointKey)
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case discoveryDictionary
        case authorizationEndpoint
        case tokenEndpoint
        case issuer
        case registrationEndpoint
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
  //      discoveryDictionary = try? values.decode([String : Any].self, forKey: .discoveryDictionary)    // Need to handle Any in Codable!!!!!
        authorizationEndpoint = try? values.decode(URL.self, forKey: .authorizationEndpoint)
        tokenEndpoint = try? values.decode(URL.self, forKey: .tokenEndpoint)
        issuer = try? values.decode(URL.self, forKey: .issuer)
        registrationEndpoint = try? values.decode(URL.self, forKey: .registrationEndpoint)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(discoveryDictionary, forKey: CodingKeys.discoveryDictionary)
        try container.encode(authorizationEndpoint, forKey: CodingKeys.authorizationEndpoint)
        try container.encode(tokenEndpoint, forKey: .tokenEndpoint)
        try container.encode(issuer, forKey: CodingKeys.issuer)
        try container.encode(registrationEndpoint, forKey: .registrationEndpoint)
    }
    
    
    // MARK: - Utilities
    
    // Throws an error if not all required fields present.
    static func dictionaryHasRequiredFields(dictionary: [String : Any]) throws {
        let requiredFields = [
            kIssuerKey,
            kAuthorizationEndpointKey,
            kTokenEndpointKey,
            kJWKSURLKey,
            kResponseTypesSupportedKey,
            kSubjectTypesSupportedKey,
            kIDTokenSigningAlgorithmValuesSupportedKey
        ]
        
        for field in requiredFields {
            if dictionary[field] == nil {
                throw ProviderConfigurationError.missingField(field)
            }
        }
        
        let requiredURLFields = [
            kIssuerKey,
            kTokenEndpointKey,
            kJWKSURLKey
        ]
        
        for field in requiredURLFields {
            guard let urlString = dictionary[field] as? String,
                let _ = URL(string: urlString) else {
                throw ProviderConfigurationError.couldNotConvertURLField(field)
            }
        }
    }
    
    func description()->String {
        return "===========\nProviderConfiguration \nauthorizationEndpoint: \(String(describing: authorizationEndpoint)), \ntokenEndpoint: \(String(describing: tokenEndpoint)), \nregistrationEndpoint: \(String(describing: registrationEndpoint)), \ndiscoveryDictionary: \(String(describing: discoveryDictionary))\n============="
    }
}
