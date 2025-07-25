//
//  LegacyPreferencesHelper.swift
//  LegacyPreferencesHelper
//
//  Created by acer51-doctom on 16/07/2025.
//

import Foundation

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class LegacyPreferencesHelper: NSObject, LegacyPreferencesHelperProtocol {
    
    /// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
    @objc func performCalculation(firstNumber: Int, secondNumber: Int, with reply: @escaping (Int) -> Void) {
        let response = firstNumber + secondNumber
        reply(response)
    }
}
