import XCTest
@testable import SolidAuthSwiftTools
import SwiftJWT
import CryptorRSA

final class SolidAuthSwiftToolsTests: XCTestCase {
    // The key pair setup using tshe method given here: https://github.com/Kitura/Swift-JWT
    // And transformed for json using: https://stackoverflow.com/questions/38672680/replace-newlines-with-literal-n/38674872
    // See also:
    // Once generated from the Apple developer's website, the key is converted
    // to a single line for the JSON using:
    //      awk 'NF {sub(/\r/, ""); printf "%s\\\\n",$0;}' *.p8
    // Script from https://docs.vmware.com/en/Unified-Access-Gateway/3.0/com.vmware.access-point-30-deploy-config.doc/GUID-870AF51F-AB37-4D6C-B9F5-4BFEB18F11E9.html
    
    // The DPoP.swift file has instructions for generating the JWK. After that, I used:
    //      sed -E 's/([^\]|^)"/\1\\"/g' < privateKey.jwk
    // to escape the double quotes
    
    let keyPairFile = URL(fileURLWithPath: "../Private/SolidAuthSwiftTools/keyPair.json")
    var keyPair:KeyPair!
    
    override func setUp() {
        super.setUp()
        guard let keyPair = try? KeyPair.loadFrom(file: keyPairFile) else {
            XCTFail()
            return
        }
        self.keyPair = keyPair
    }
    
    func testCreatePublicAndPrivateKeys() throws {
        guard let publicKeyString = keyPair?.publicKey else {
            XCTFail()
            return
        }
        
        let _ = try CryptorRSA.createPublicKey(withPEM: publicKeyString)

        guard let privateKeyString = keyPair?.privateKey else {
            XCTFail()
            return
        }
        
        let _ = try CryptorRSA.createPrivateKey(withPEM: privateKeyString)
    }
    
    func testDPoPSigner() throws {
        guard let jwk = keyPair?.jwk else {
            XCTFail()
            return
        }
                
        guard let privateKey = keyPair?.privateKey else {
            XCTFail()
            return
        }
        
        let body = BodyClaims(htu: "https://secureauth.example/token", htm: "POST", jti: "4ba3e9ef-e98d-4644-9878-7160fa7d3eb8")
        
        let dpop = DPoP(jwk: jwk, privateKey: privateKey, body: body)
        let signed = try dpop.generate()
        
        print("signedJWT: \(signed)")
    }
}
