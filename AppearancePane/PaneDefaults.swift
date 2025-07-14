//
//  PaneDefaults.swift
//  AppearancePane
//
//  Created by dehydratedpotato on 6/1/23.
//

import SwiftUI

final class PaneDefaults: ObservableObject {
    // MARK: - Static Properties
    static let bundle: Bundle = .init(identifier: "com.acer51-doctom.Legacy-Preferences.AppearancePane")!
    static let paneHeight: CGFloat = 620
    static let maximumPickerWidth: CGFloat = 170
    static let labelColumnWidth: CGFloat = 230
    
    static let accentTypeNameTable: [String] = [
        "Red",
        "Orange",
        "Yellow",
        "Green",
        "Blue",
        "Purple",
        "Pink",
        "Graphite",
        "Multicolor"
    ]
    
    static let highlightTypeNameTable: [String] = [
        "Red",
        "Orange",
        "Yellow",
        "Green",
        "Blue",
        "Purple",
        "Pink",
        "Graphite",
        "Accent Color"
    ]
    
    // MARK: - Types
    
    enum ThemeType: String {
        case light = "Light"
        case dark = "Dark"
        case auto = "Auto"
    }
    
    enum AccentType: Int {
        case red = 0
        case orange = 1
        case yellow = 2
        case green = 3
        case blue = 4
        case purple = 5
        case pink = 6
        case gray = 7 // Corresponds to -1 in NSColorGetUserAccentColor
        case multicolor = 8 // Corresponds to -2 in NSColorGetUserAccentColor
    }
    
    enum HighlightType: Int {
        case red = 0
        case orange = 1
        case yellow = 2
        case green = 3
        case blue = 4
        case purple = 5
        case pink = 6
        case gray = 7 // Corresponds to -2 in NSColorGetUserHighlightColor
        case accentcolor = 8 // Corresponds to -1 in NSColorGetUserHighlightColor
    }
    
    struct Accent: Identifiable {
        let id: AccentType
        let color: Color
    }
    
    struct Theme: Identifiable {
        let id: ThemeType
        let hint: String
    }
    
    enum ShowScrollbarType: String {
        case whenScrolling = "WhenScrolling"
        case auto = "Automatic"
        case always = "Always"
    }
    
    enum TabbingModeType: String {
        case fullscreen = "fullscreen"
        case always = "always"
        case never = "never"
    }
    
    
    // MARK: - Theme logic
    
    // Note: SLSGetAppearanceThemeLegacy and SLSGetAppearanceThemeSwitchesAutomatically
    // are Objective-C functions declared in AppearancePane.h and assumed to be correctly bridged.
    // They are not directly reading from UserDefaults.globalDomain.
    var themeIsDark: Bool {
        // Provide a default if SLSGetAppearanceThemeLegacy fails or returns unexpected value
        return SLSGetAppearanceThemeLegacy() == .dark
    }

    var themeIsAuto: Bool {
        // Provide a default if SLSGetAppearanceThemeSwitchesAutomatically fails or returns unexpected value
        return SLSGetAppearanceThemeSwitchesAutomatically() == 1
    }
    
    lazy var startTheme: ThemeType = {
        if self.themeIsDark {
            return .dark
        }
        if self.themeIsAuto {
           return .auto
        }
        return .light
    }()
    
    func setInterfaceStyle(isDark: Bool, isAuto: Bool) {
        if isDark {
            SLSSetAppearanceThemeLegacy(.dark)
        } else {
            SLSSetAppearanceThemeLegacy(.light)
        }
        
        if isAuto {
            SLSSetAppearanceThemeSwitchesAutomatically(1)
        } else {
            SLSSetAppearanceThemeSwitchesAutomatically(0)
        }
        
        Logger.log("isDark: \(self.themeIsDark), isAuto: \(self.themeIsAuto)", class: Self.self)
    }
    
    // MARK: - Accent color logic
    
    // Note: NSColorGetUserAccentColor is an Objective-C function declared in AppearancePane.h
    // and assumed to be correctly bridged.
    lazy var startAccentColor: AccentType = {
        let color = NSColorGetUserAccentColor()
        
        switch color {
        case -1:
            return .gray
        case -2:
            return .multicolor
        default:
            // Safely convert raw value to AccentType, default to .multicolor if invalid
            return AccentType(rawValue: Int(color)) ?? .multicolor
        }
    }()
    
    func setAccentColor(toType type: PaneDefaults.AccentType) {
        // This line attempts to set highlight color based on accent color.
        // Ensure HighlightType(rawValue: type.rawValue) is valid, otherwise it will crash.
        // Given the raw values match, this should be fine.
        self.setHighlightColor(toType: PaneDefaults.HighlightType(rawValue: type.rawValue)!)
        
        switch type {
        case .multicolor:
            NSColorSetUserAccentColor(-2)
        case .gray:
            NSColorSetUserAccentColor(-1)
        default:
            NSColorSetUserAccentColor(Int32( type.rawValue))
        }
        
        Logger.log("accentColor: \(type)", class: Self.self)
    }
    
    // MARK: - Highlight color logic
    
    // Note: NSColorGetUserHighlightColor is an Objective-C function declared in AppearancePane.h
    // and assumed to be correctly bridged.
    lazy var startHighlightColor: HighlightType = {
        let color = NSColorGetUserHighlightColor()
        
        switch color {
        case -2:
            return .gray
        case -1:
            return .accentcolor
        default:
            // Safely convert raw value to HighlightType, default to .accentcolor if invalid
            return HighlightType(rawValue: Int(color)) ?? .accentcolor
        }
    }()
    
    func setHighlightColor(toType type: PaneDefaults.HighlightType) {
        switch type {
        case .accentcolor:
            NSColorSetUserAccentColor(-1) // This seems to be setting accent color, not highlight.
                                          // Based on original code, this might be intentional but unusual.
        case .gray:
            NSColorSetUserAccentColor(-2) // This also seems to be setting accent color.
                                          // Check if NSColorSetUserHighlightColor should be used here.
        default:
            NSColorSetUserHighlightColor(Int32( type.rawValue))
        }
        
        Logger.log("highlightColor: \(type)", class: Self.self)
    }
    
    // MARK: - Sidebar size logic
    
    static let sidebarSizeKey = "NSTableViewDefaultSizeMode"
    static let sidebarSizeNotifKey = "AppleSideBarDefaultIconSizeChanged"
    
    lazy var startSidebarSize: Int = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get sidebar size domain (globalDomain was nil). Defaulting to 2.", isError: true, class: Self.self)
            return 2 // Default to medium if domain is entirely inaccessible
        }

        // Safely try to get the value for 'NSTableViewDefaultSizeMode'.
        // If the key doesn't exist or is not an Int, use '2' (Medium) as the default.
        return (domain[PaneDefaults.sidebarSizeKey] as? Int) ?? 2
    }()
     
    func setSidebarSize(toSize size: Int) -> Bool {
        // Ensure we can get the global domain and that it's mutable.
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting sidebar size", isError: true, class: Self.self)
            return false
        }
        
        // No need to check domain.contains(where: { $0.key == PaneDefaults.sidebarSizeKey })
        // as setting a key that doesn't exist will simply add it.
        domain[PaneDefaults.sidebarSizeKey] = size
        
        UserDefaults.standard.setPersistentDomain(domain, forName:  UserDefaults.globalDomain)
        
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.sidebarSizeNotifKey), object: nil)
        
        Logger.log("sidebarSize: \(size)", class: Self.self)
        
        return true
    }
    
    // MARK: - Wallpaper tinting logic
    
    static let wallpaperTintingKey = "AppleReduceDesktopTinting"
    static let wallpaperTintingNotifKey = "AppleReduceDesktopTintingChanged"
    
    lazy var startWallpaperTinting: Bool = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get tint value domain (globalDomain was nil). Defaulting to true (tinting enabled).", isError: true, class: Self.self)
            return true // Default to true (tinting enabled) if domain is entirely inaccessible
        }

        // Safely try to get the value for 'AppleReduceDesktopTinting'.
        // If the key doesn't exist or is not a Bool, use 'false' as the default (meaning tinting is NOT reduced).
        // The UI toggle 'Allow wallpaper tinting in windows' is `isOn: tinting`.
        // If `AppleReduceDesktopTinting` is true, tinting is reduced, so the UI toggle should be `false`.
        // If `AppleReduceDesktopTinting` is false, tinting is not reduced, so the UI toggle should be `true`.
        let reduceTintingValue = (domain[PaneDefaults.wallpaperTintingKey] as? Bool) ?? false
        return !reduceTintingValue
    }()
    
    func setWallpaperTint(to value: Bool)-> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting tint value", isError: true, class: Self.self)
            return false
        }

        // The UI toggle `value` means 'Allow wallpaper tinting'.
        // The preference key `AppleReduceDesktopTinting` means 'REDUCE tinting'.
        // So, if `value` is true (allow tinting), we want `AppleReduceDesktopTinting` to be false (don't reduce).
        // If `value` is false (don't allow tinting), we want `AppleReduceDesktopTinting` to be true (reduce).
        domain[PaneDefaults.wallpaperTintingKey] = !value
        
        UserDefaults.standard.setPersistentDomain(domain, forName:  UserDefaults.globalDomain)
        
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.wallpaperTintingNotifKey), object: nil)
        
        Logger.log("reduceTinting: \(!value)", class: Self.self) // Log the actual preference value being set
        
        return true
    }
    
    // MARK: - Show scrollbar logic
    
    static let showScrollbarKey = "AppleShowScrollBars"
    static let showScrollbarNotifKey = "AppleShowScrollBarsSettingChanged"
    
    lazy var startShowScrollbars: ShowScrollbarType = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get scrollbar show type domain (globalDomain was nil). Defaulting to .auto.", isError: true, class: Self.self)
            return .auto
        }

        // Safely try to get the value for 'AppleShowScrollBars' as a String.
        // If the key doesn't exist or is not a String, use '.auto' as the default.
        let rawValue = (domain[PaneDefaults.showScrollbarKey] as? String) ?? ShowScrollbarType.auto.rawValue
        return ShowScrollbarType(rawValue: rawValue) ?? .auto
    }()
    
    func setShowScrollbars(to value: ShowScrollbarType) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting scrollbar show type", isError: true, class: Self.self)
            return false
        }

        domain[PaneDefaults.showScrollbarKey] = value.rawValue
        
        UserDefaults.standard.setPersistentDomain(domain, forName:  UserDefaults.globalDomain)
        
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.showScrollbarNotifKey), object: nil)
        
        Logger.log("showScrollbar: \(value)", class: Self.self)
        
        return true
    }
    
    // MARK: - Jump to page logic & Close windows when quit and Confirm close quitting logic
    
    static let windowQuitKey = "NSQuitAlwaysKeepsWindows"
    static let closeAlwaysConfirms = "NSCloseAlwaysConfirmsChanges"
    static let jumpPageKey = "AppleScrollerPagingBehavior" // This key is for "Jump to the next page" vs "Jump to the spot that's clicked"
    
    lazy var startJumpPage: Bool = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get jump page value domain (globalDomain was nil). Defaulting to false.", isError: true, class: Self.self)
            return false // Default to false (Jump to the next page)
        }

        // Safely try to get the value for 'AppleScrollerPagingBehavior'.
        // If the key doesn't exist or is not a Bool, use 'false' as the default.
        return (domain[PaneDefaults.jumpPageKey] as? Bool) ?? false
    }()
    
    lazy var startWindowQuit: Bool = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get window quitting value domain (globalDomain was nil). Defaulting to false.", isError: true, class: Self.self)
            return false // Default to false
        }

        // Safely try to get the value for 'NSQuitAlwaysKeepsWindows'.
        // If the key doesn't exist or is not a Bool, use 'false' as the default.
        return (domain[PaneDefaults.windowQuitKey] as? Bool) ?? false
    }()
    
    lazy var startcloseAlwaysConfirms: Bool = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get close always confirm value domain (globalDomain was nil). Defaulting to false.", isError: true, class: Self.self)
            return false // Default to false
        }

        // Safely try to get the value for 'NSCloseAlwaysConfirmsChanges'.
        // If the key doesn't exist or is not a Bool, use 'false' as the default.
        return (domain[PaneDefaults.closeAlwaysConfirms] as? Bool) ?? false
    }()
    
    func setBool(for key: String, to value: Bool) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting bool value for \(key)", isError: true, class: Self.self)
            return false
        }

        // No need to check domain.contains(where: { $0.key == key })
        // as setting a key that doesn't exist will simply add it.
        domain[key] = value
        
        UserDefaults.standard.setPersistentDomain(domain, forName:  UserDefaults.globalDomain)
        
        Logger.log("\(key): \(value)", class: Self.self)
        
        return true
    }

    // MARK: - Tabbing mode logic
    
    static let tabbingModeKey = "AppleWindowTabbingMode"
    
    lazy var startTabbingMode: TabbingModeType = {
        // Safely get the global domain. If it's nil, we use a fallback default.
        guard let domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get tabbing mode type domain (globalDomain was nil). Defaulting to .fullscreen.", isError: true, class: Self.self)
            return .fullscreen
        }

        // Safely try to get the value for 'AppleWindowTabbingMode' as a String.
        // If the key doesn't exist or is not a String, use '.fullscreen' as the default.
        let rawValue = (domain[PaneDefaults.tabbingModeKey] as? String) ?? TabbingModeType.fullscreen.rawValue
        return TabbingModeType(rawValue: rawValue) ?? .fullscreen
    }()
    
    func setTabbingMode(to value: TabbingModeType) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting tabbing mode type", isError: true, class: Self.self)
            return false
        }

        domain[PaneDefaults.tabbingModeKey] = value.rawValue
        
        UserDefaults.standard.setPersistentDomain(domain, forName:  UserDefaults.globalDomain)
        
        Logger.log("tabbingMode: \(value)", class: Self.self)
        
        return true
    }
}
