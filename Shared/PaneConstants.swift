//
//  PaneConstants.swift
//  Legacy Preferences
//
//  Created by dehydratedpotato on 6/6/23.
//  Maintained by acer51-doctom since 16/07/2025.
//

import Foundation

struct PaneConstants {
    static let paneWidth: CGFloat = 668
    static let panePadding: CGFloat = 20
    
    // TODO: Revise this when all pausible panes are finished
    static let supportTable: [Bool] = [
        false, // desktop
        false, // dock
        false, // missionControl
        false, // siri
        false, // spotlight
        false, // language
        false, // notifications
        false, // users
        false, // accessibility
        false, // security
        false, // network
        false, // bluetooth
        false, // sound
        false, // printersAndScanners
        false, // keyboard
        false, // trackpad
        false, // mouse
        false, // displays
        false, // battery
        false, // dataAndTime
//        false, // sharing; commented out because no icons
        false, // energySaver
//        false, // sidecar; commented out because no icons
//        false, // wallet; commented out because no icons
//        false, // touchID; commented out because no icons
        false, // internetAccounts
        false, // startupDisk
        false, // screenTime
        false, // softwareUpdate
        false, // timeMachine
        false, // appleID
        false, // familySharing
        true // appearance
    ]
    
    static let nameTable: [String] = [
        "Desktop & Screensaver",
        "Dock & Menu Bar",
        "Mission Control",
        "Siri",
        "Spotlight",
        "Language & Region",
        "Notifications",
        "Users & Groups",
        "Accessibility",
        "Security & Privacy",
        "Network",
        "Bluetooth",
        "Sound",
        "Printers & Scanners",
        "Keyboard",
        "Trackpad",
        "Mouse",
        "Displays",
        "Battery",
        "Date & Time",
//        "Sharing",; commented out because no icons
        "Energy Saver",
//        "Sidecar",; commented out because no icons
//        "Wallet",; commented out because no icons
//        "TouchID",; commented out because no icons
        "Internet Accounts",
        "Startup Disk",
        "Screen Time",
        "Software Update",
        "Time Machine",
        "Apple ID",
        "Family Sharing",
        "General"
    ]
    
    static let priTable: [UInt32] = [
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        13,
        14,
        17,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        29,
        30,
//        31,; commented out because no icons
        28,
//        27,; commented out because no icons
//        11,; commented out because no icons
//        12,; commented out because no icons
        10,
        33,
        15,
        18,
        32,
        0,
        1,
        2,
    ]
    
    enum PaneType: Int, CaseIterable {
        case desktopAndScreensaver = 0
        case dockAndMenubar
        case missionControl
        case siri
        case spotlight
        case languageAndRegion
        case notification
        case users
        case accessibility
        case security
        case network
        case bluetooth
        case sound
        case printersAndScanners
        case keyboard
        case trackpad
        case mouse
        case displays
        case battery
        case dataAndTime
//        case sharing; commented out because no icons
        case energySaver
//        case sidecar; commented out because no icons
//        case wallet; commented out because no icons
//        case touchID; commented out because no icons
        case internetAccounts
        case startupDisk
        case screenTime
        case softwareUpdate
        case timeMachine
        case appleID
        case familySharing
        case appearance
    }
}
