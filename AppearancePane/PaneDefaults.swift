//
//  PaneDefaults.swift
//  AppearancePane
//
//  Created by dehydratedpotato on 6/1/23.
//  Maintained by acer51-doctom since 14/07/2025 (DD-MM-YYYY)
//

import SwiftUI
import CoreServices // Import CoreServices for LaunchServices APIs
import AppKit // Required for NSImage and NSWorkspace

final class PaneDefaults: ObservableObject {
    // MARK: - Static Properties
    static let bundle: Bundle = .init(identifier: "com.acer51-doctom.Legacy-Preferences.AppearancePane")!
    static let paneHeight: CGFloat = 620
    static let maximumPickerWidth: CGFloat = 170
    static let labelColumnWidth: CGFloat = 230
    
    // Easily modifiable list of popular browser bundle IDs.
    // Add or remove bundle IDs here to change which browsers are searched for.
    static let popularBrowserBundleIDs: Set<String> = [
        "com.google.Chrome",      // Google Chrome
        "org.chromium.Chromium",  // Chromium
        "com.apple.Safari",       // Safari
        "org.mozilla.firefox",    // Mozilla Firefox
        "com.kagi.Orion",         // Orion Browser
        "com.arc.browser"         // Arc Browser
    ]
    
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
    
    enum AccentType: Int, CaseIterable, Identifiable {
        case red = 0
        case orange = 1
        case yellow = 2
        case green = 3
        case blue = 4
        case purple = 5
        case pink = 6
        case gray = 7 // Corresponds to -1 in NSColorGetUserAccentColor
        case multicolor = 8 // Corresponds to -2 in NSColorGetUserAccentColor
        public var id: Int { self.rawValue }
    }
    
    enum HighlightType: Int, CaseIterable, Identifiable {
        case red = 0
        case orange = 1
        case yellow = 2
        case green = 3
        case blue = 4
        case purple = 5
        case pink = 6
        case gray = 7 // Corresponds to -2 in NSColorGetUserHighlightColor
        case accentcolor = 8 // Corresponds to -1 in NSColorGetUserHighlightColor
        public var id: Int { self.rawValue }
    }
    
    struct Accent: Identifiable {
        let id: AccentType
        let color: Color
    }
    
    struct Theme: Identifiable {
        let id: ThemeType
        let hint: String
    }
    
    enum ShowScrollbarType: String, CaseIterable, Identifiable {
        case whenScrolling = "WhenScrolling"
        case auto = "Automatic"
        case always = "Always"
        public var id: String { self.rawValue }
    }
    
    enum TabbingModeType: String, CaseIterable, Identifiable {
        case fullscreen = "fullscreen"
        case always = "always"
        case never = "never"
        public var id: String { self.rawValue }
    }
    
    struct BrowserInfo: Identifiable, Hashable {
        let id: String // Bundle Identifier
        let name: String
        let icon: NSImage? // To display the app icon
    }
    
    // MARK: - Default Web Browser Properties
    @Published var defaultBrowserIdentifier: String = ""
    @Published var availableBrowsers: [BrowserInfo] = []
    
    // MARK: - Initializer Properties
    @Published var startWallpaperTinting: Bool
    @Published var startSidebarSize: Int
    @Published var startShowScrollbars: ShowScrollbarType
    @Published var startWindowQuit: Bool
    @Published var startcloseAlwaysConfirms: Bool
    @Published var startTabbingMode: TabbingModeType
    @Published var startJumpPage: Bool
    @Published var startHandoffEnabled: Bool // New: Handoff Enabled
    
    lazy var startTheme: ThemeType = {
        if self.themeIsDark {
            return .dark
        }
        if self.themeIsAuto {
            return .auto
        }
        return .light
    }()
    
    lazy var startAccentColor: AccentType = {
        let color = NSColorGetUserAccentColor()
        switch color {
        case -1:
            return .gray
        case -2:
            return .multicolor
        default:
            return AccentType(rawValue: Int(color)) ?? .multicolor
        }
    }()
    
    lazy var startHighlightColor: HighlightType = {
        let color = NSColorGetUserHighlightColor()
        switch color {
        case -2:
            return .gray
        case -1:
            return .accentcolor
        default:
            return HighlightType(rawValue: Int(color)) ?? .accentcolor
        }
    }()
    
    // MARK: - Preference Keys
    static let sidebarSizeKey = "NSTableViewDefaultSizeMode"
    static let sidebarSizeNotifKey = "AppleSideBarDefaultIconSizeChanged"
    static let wallpaperTintingKey = "AppleReduceDesktopTinting"
    static let wallpaperTintingNotifKey = "AppleReduceDesktopTintingChanged"
    static let showScrollbarKey = "AppleShowScrollBars"
    static let showScrollbarNotifKey = "AppleShowScrollBarsSettingChanged"
    static let windowQuitKey = "NSQuitAlwaysKeepsWindows"
    static let closeAlwaysConfirms = "NSCloseAlwaysConfirmsChanges"
    static let jumpPageKey = "AppleScrollerPagingBehavior"
    static let tabbingModeKey = "AppleWindowTabbingMode"
    static let handoffEnabledKey = "NSUserActivityTrackingEnabled" // Key for Handoff
    static let handoffActivityContinuationKey = "NSUserActivityTrackingEnabledForActivityContinuation" // Another related key for Handoff
    
    // MARK: - Initializer
    public init() {
        let globalDomain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        
        self.startWallpaperTinting = !(globalDomain?[PaneDefaults.wallpaperTintingKey] as? Bool ?? false)
        self.startSidebarSize = (globalDomain?[PaneDefaults.sidebarSizeKey] as? Int) ?? 2
        let rawScrollbarValue = (globalDomain?[PaneDefaults.showScrollbarKey] as? String) ?? ShowScrollbarType.auto.rawValue
        self.startShowScrollbars = ShowScrollbarType(rawValue: rawScrollbarValue) ?? .auto
        self.startWindowQuit = (globalDomain?[PaneDefaults.windowQuitKey] as? Bool) ?? false
        self.startcloseAlwaysConfirms = (globalDomain?[PaneDefaults.closeAlwaysConfirms] as? Bool) ?? false
        self.startJumpPage = (globalDomain?[PaneDefaults.jumpPageKey] as? Bool) ?? false
        let rawTabbingModeValue = (globalDomain?[PaneDefaults.tabbingModeKey] as? String) ?? TabbingModeType.fullscreen.rawValue
        self.startTabbingMode = TabbingModeType(rawValue: rawTabbingModeValue) ?? .fullscreen
        
        // Initialize Handoff state. Both keys should ideally be in sync.
        let isHandoffEnabled = (globalDomain?[PaneDefaults.handoffEnabledKey] as? Bool) ?? true
        let isActivityContinuationEnabled = (globalDomain?[PaneDefaults.handoffActivityContinuationKey] as? Bool) ?? true
        self.startHandoffEnabled = isHandoffEnabled && isActivityContinuationEnabled // Consider Handoff enabled only if both are true
        
        loadBrowsers()
    }
    
    // MARK: - Theme logic
    func setInterfaceStyle(isDark: Bool, isAuto: Bool) {
        SLSSetAppearanceThemeLegacy(isDark ? .dark : .light)
        SLSSetAppearanceThemeSwitchesAutomatically(isAuto ? 1 : 0)
        Logger.log("isDark: \(self.themeIsDark), isAuto: \(self.themeIsAuto)", class: Self.self)
    }
    
    var themeIsDark: Bool {
        return SLSGetAppearanceThemeLegacy() == .dark
    }
    
    var themeIsAuto: Bool {
        return SLSGetAppearanceThemeSwitchesAutomatically() == 1
    }
    
    // MARK: - Accent color logic
    func setAccentColor(toType type: PaneDefaults.AccentType) {
        self.setHighlightColor(toType: PaneDefaults.HighlightType(rawValue: type.rawValue)!)
        
        switch type {
        case .multicolor: NSColorSetUserAccentColor(-2)
        case .gray: NSColorSetUserAccentColor(-1)
        default: NSColorSetUserAccentColor(Int32(type.rawValue))
        }
        Logger.log("accentColor: \(type)", class: Self.self)
    }
    
    // MARK: - Highlight color logic
    func setHighlightColor(toType type: PaneDefaults.HighlightType) {
        switch type {
        case .accentcolor:
            NSColorSetUserHighlightColor(-1)
        case .gray:
            NSColorSetUserHighlightColor(-2)
        default:
            NSColorSetUserHighlightColor(Int32(type.rawValue))
        }
        Logger.log("highlightColor: \(type)", class: Self.self)
    }
    
    // MARK: - Sidebar size logic
    func setSidebarSize(toSize size: Int) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting sidebar size", isError: true, class: Self.self)
            return false
        }
        domain[PaneDefaults.sidebarSizeKey] = size
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.sidebarSizeNotifKey), object: nil)
        Logger.log("sidebarSize: \(size)", class: Self.self)
        return true
    }
    
    // MARK: - Wallpaper tinting logic
    func setWallpaperTint(to value: Bool) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting tint value", isError: true, class: Self.self)
            return false
        }
        domain[PaneDefaults.wallpaperTintingKey] = !value
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.wallpaperTintingNotifKey), object: nil)
        Logger.log("reduceTinting: \(!value)", class: Self.self)
        return true
    }
    
    // MARK: - Show scrollbar logic
    func setShowScrollbars(to value: ShowScrollbarType) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting scrollbar show type", isError: true, class: Self.self)
            return false
        }
        domain[PaneDefaults.showScrollbarKey] = value.rawValue
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.showScrollbarNotifKey), object: nil)
        Logger.log("showScrollbar: \(value)", class: Self.self)
        return true
    }
    
    // MARK: - General Bool Setter
    func setBool(for key: String, to value: Bool) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting bool value for \(key)", isError: true, class: Self.self)
            return false
        }
        domain[key] = value
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("\(key): \(value)", class: Self.self)
        return true
    }
    
    // MARK: - Tabbing mode logic
    func setTabbingMode(to value: TabbingModeType) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting tabbing mode type", isError: true, class: Self.self)
            return false
        }
        domain[PaneDefaults.tabbingModeKey] = value.rawValue
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("tabbingMode: \(value)", class: Self.self)
        return true
    }
    
    // MARK: - Handoff Logic (New)
    func setHandoffEnabled(to value: Bool) -> Bool {
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("failed to get global domain for setting Handoff enabled state", isError: true, class: Self.self)
            return false
        }
        
        // Set both related keys for Handoff
        domain[PaneDefaults.handoffEnabledKey] = value
        domain[PaneDefaults.handoffActivityContinuationKey] = value
        
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        // Handoff changes might require a logout/login or reboot to take full effect,
        // and there isn't a simple public notification to trigger an immediate update across all apps.
        Logger.log("Handoff enabled set to: \(value)", class: Self.self)
        return true
    }
    
    // MARK: - Default Web Browser Logic
    // Function to load available web browsers and the current default
    func loadBrowsers() {
        // Get all applications that can handle HTTP and HTTPS schemes
        let httpHandlers = LSCopyAllHandlersForURLScheme("http" as CFString)?.takeRetainedValue() as? [String] ?? []
        let httpsHandlers = LSCopyAllHandlersForURLScheme("https" as CFString)?.takeRetainedValue() as? [String] ?? []
        
        // Combine and get unique bundle identifiers, then filter by popular browsers
        let allHandlers = Set(httpHandlers + httpsHandlers)
        let filteredHandlers = allHandlers.filter { PaneDefaults.popularBrowserBundleIDs.contains($0) }
        
        var browsers: [BrowserInfo] = []
        for bundleID in filteredHandlers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
               let bundle = Bundle(url: url),
               let appName = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
                
                // Get the application icon
                let appIcon = NSWorkspace.shared.icon(forFile: url.path)
                appIcon.size = NSSize(width: 32, height: 32) // Standard icon size for UI
                
                browsers.append(BrowserInfo(id: bundleID, name: appName, icon: appIcon))
            }
        }
        
        // Sort browsers alphabetically by name
        self.availableBrowsers = browsers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        // Get the current default browser
        if let defaultHTTPHandler = LSCopyDefaultHandlerForURLScheme("http" as CFString)?.takeRetainedValue() as? String {
            self.defaultBrowserIdentifier = defaultHTTPHandler
        } else {
            self.defaultBrowserIdentifier = "" // No default browser found or error
        }
        
        Logger.log("Loaded \(self.availableBrowsers.count) browsers. Default: \(self.defaultBrowserIdentifier)", class: Self.self)
    }
    
    // Function to set the default web browser
    func setDefaultWebBrowser(bundleIdentifier: String) {
        let httpScheme = "http" as CFString
        let httpsScheme = "https" as CFString
        
        // Set default handler for both HTTP and HTTPS schemes
        let statusHTTP = LSSetDefaultHandlerForURLScheme(httpScheme, bundleIdentifier as CFString)
        let statusHTTPS = LSSetDefaultHandlerForURLScheme(httpsScheme, bundleIdentifier as CFString)
        
        if statusHTTP == noErr && statusHTTPS == noErr {
            Logger.log("Successfully set default browser to \(bundleIdentifier)", class: Self.self)
            // Update the published property to reflect the change
            self.defaultBrowserIdentifier = bundleIdentifier
            
            // Post notification to inform other apps of the change (optional, but good practice)
            DistributedNotificationCenter.default().post(name: .init("ApplePreferredBrowserChanged"), object: nil)
        } else {
            Logger.log("Failed to set default browser to \(bundleIdentifier). HTTP Status: \(statusHTTP), HTTPS Status: \(statusHTTPS)", isError: true, class: Self.self)
        }
    }
}
