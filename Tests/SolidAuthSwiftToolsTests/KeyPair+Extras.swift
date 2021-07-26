//
//  KeyPair+Extras.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
import SolidAuthSwiftTools

extension KeyPair {
    static func loadFrom(file: URL) throws -> KeyPair {
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(KeyPair.self, from: data)
    }
}
