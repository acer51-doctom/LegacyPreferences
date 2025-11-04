//
//  HelperToolProtocol.swift
//  LegacyPreferences
//
//  Created by acer51-doctom on 16/07/2025.
//

import Foundation

@objc(HelperToolProtocol)
public protocol HelperToolProtocol: NSObjectProtocol {
    func setRecentItemsCount(count: Int, withReply completion: @escaping (Bool) -> Void)
}
