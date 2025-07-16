//
//  HelperToolProtocol.swift
//  Legacy Preferences
//
//  Created by acer51-doctom on 16/07/2025.
//

import Foundation

// Define the protocol that the XPC Service will implement and the main app will use.
// This protocol must inherit from NSSecureCoding if you pass custom objects,
// or just NSObjectProtocol if only basic types are used.
@objc(HelperToolProtocol)
protocol HelperToolProtocol: NSObjectProtocol {
    /// Sets the number of recent items in macOS.
    /// This operation typically requires elevated privileges.
    /// - Parameters:
    ///   - count: The desired number of recent items.
    ///   - completion: A closure to be called upon completion, indicating success or failure.
    func setRecentItemsCount(count: Int, withReply completion: @escaping (Bool) -> Void)
}
