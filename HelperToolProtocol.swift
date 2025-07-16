//
//  HelperToolProtocol.swift
//  LegacyPreferences
//
//  Created by acer51-doctom on 16/07/2025.
//

import Foundation // Ensure Foundation is explicitly imported for NSObjectProtocol

// Define the protocol that the XPC Service will implement and the main app will use.
// This protocol must inherit from NSObjectProtocol for XPC.
@objc(HelperToolProtocol) // @objc is crucial for XPC to bridge to Objective-C runtime
public protocol HelperToolProtocol: NSObjectProtocol {
    /// Sets the number of recent items in macOS.
    /// This operation typically requires elevated privileges.
    /// - Parameters:
    ///   - count: The desired number of recent items.
    ///   - completion: A closure to be called upon completion, indicating success or failure.
    func setRecentItemsCount(count: Int, withReply completion: @escaping (Bool) -> Void)
}
