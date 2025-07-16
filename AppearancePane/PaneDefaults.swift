//
//  PaneDefaults.swift
//  AppearancePane
//
//  Created by dehydratedpotato on 6/1/23.
//  Maintained by acer51-doctom since 14/07/2025 (DD-MM-YYYY)
//
//  This version re-organizes the PaneDefaults class for clarity and consistency,
//  while maintaining all original functionalities for managing macOS appearance settings.

import SwiftUI
import CoreServices // For LaunchServices APIs (e.g., default web browser)
import AppKit // For NSImage, NSWorkspace, NSColorGetUserAccentColor, etc.
import Combine // For ObservableObject and @Published properties
import Foundation // For UserDefaults, NSXPCConnection, DistributedNotificationCenter, etc.

// IMPORTANT: Ensure HelperToolProtocol.swift is correctly added to both
// your main application target and your LegacyPreferencesHelper XPC Service target.
// The protocol definition must be accessible to both for XPC communication.

final class PaneDefaults: ObservableObject {
    // MARK: - Static Properties & Constants
    
    // Bundle identifier for the AppearancePane framework itself.
    // Used for loading resources (like images) specific to this pane's bundle.
    static let bundle: Bundle = .init(identifier: "com.acer51-doctom.Legacy-Preferences.AppearancePane")!
    
    // UI layout constants.
    static let paneHeight: CGFloat = 620
    static let maximumPickerWidth: CGFloat = 170
    static let labelColumnWidth: CGFloat = 230
    
    // List of popular browser bundle IDs to filter for in the default browser picker.
    static let popularBrowserBundleIDs: Set<String> = [
        "com.google.Chrome",      // Google Chrome
        "org.chromium.Chromium",  // Chromium
        "com.apple.Safari",       // Safari
        "org.mozilla.firefox",    // Mozilla Firefox
        "com.kagi.Orion",         // Orion Browser
        "com.arc.browser"         // Arc Browser
    ]
    
    // Human-readable names for accent and highlight colors, indexed by their raw values.
    static let accentTypeNameTable: [String] = [
        "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Graphite", "Multicolor"
    ]
    static let highlightTypeNameTable: [String] = [
        "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Graphite", "Accent Color"
    ]
    
    // MARK: - Preference Keys (UserDefaults.globalDomain)
    // These static strings represent the keys used to read/write system preferences.
    static let sidebarSizeKey = "NSTableViewDefaultSizeMode"
    static let sidebarSizeNotifKey = "AppleSideBarDefaultIconSizeChanged"
    static let wallpaperTintingKey = "AppleReduceDesktopTinting"
    static let wallpaperTintingNotifKey = "AppleReduceDesktopTintingChanged"
    static let showScrollbarKey = "AppleShowScrollBars"
    static let showScrollbarNotifKey = "AppleShowScrollBarsSettingChanged"
    static let windowQuitKey = "NSQuitAlwaysKeepsWindows"
    static let closeAlwaysConfirmsKey = "NSCloseAlwaysConfirmsChanges" // Renamed for clarity
    static let jumpPageKey = "AppleScrollerPagingBehavior"
    static let tabbingModeKey = "AppleWindowTabbingMode"
    static let handoffEnabledKey = "NSUserActivityTrackingEnabled"
    static let handoffActivityContinuationKey = "NSUserActivityTrackingEnabledForActivityContinuation"
    static let recentItemsKey = "AppleShowRecentItems" // Key for Recent Items
    
    // MARK: - Enums for Preference Types
    
    enum ThemeType: String, Identifiable { // Added Identifiable for SwiftUI ForEach
        case light = "Light"
        case dark = "Dark"
        case auto = "Auto"
        public var id: String { self.rawValue }
    }
    
    enum AccentType: Int, CaseIterable, Identifiable {
        case red = 0, orange = 1, yellow = 2, green = 3, blue = 4, purple = 5, pink = 6
        case gray = 7 // Corresponds to -1 in NSColorGetUserAccentColor
        case multicolor = 8 // Corresponds to -2 in NSColorGetUserAccentColor
        public var id: Int { self.rawValue }
    }
    
    enum HighlightType: Int, CaseIterable, Identifiable {
        case red = 0, orange = 1, yellow = 2, green = 3, blue = 4, purple = 5, pink = 6
        case gray = 7 // Corresponds to -2 in NSColorGetUserHighlightColor
        case accentcolor = 8 // Corresponds to -1 in NSColorGetUserHighlightColor
        public var id: Int { self.rawValue }
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
    
    // MARK: - Structs for UI Data Models
    
    struct Accent: Identifiable {
        let id: AccentType
        let color: Color
    }
    
    struct Theme: Identifiable {
        let id: ThemeType
        let hint: String
    }
    
    struct BrowserInfo: Identifiable, Hashable {
        let id: String // Bundle Identifier
        let name: String
        let icon: NSImage? // To display the app icon
    }
    
    // MARK: - Observable Properties (Published to SwiftUI Views)
    
    // Appearance settings
    @Published var theme: ThemeType
    @Published var accentColor: AccentType
    @Published var highlightColor: HighlightType
    @Published var sidebarSize: Int
    @Published var wallpaperTinting: Bool
    @Published var showScrollbars: ShowScrollbarType
    
    // Window & Document settings
    @Published var windowQuit: Bool
    @Published var closeAlwaysConfirms: Bool
    @Published var tabbingMode: TabbingModeType
    @Published var jumpPage: Bool
    @Published var recentItemsCount: Int
    
    // Handoff setting
    @Published var handoffEnabled: Bool
    
    // Default Web Browser settings
    @Published var defaultBrowserIdentifier: String = ""
    @Published var availableBrowsers: [BrowserInfo] = []
    
    // MARK: - XPC Connection
    private var helperConnection: NSXPCConnection?
    
    // MARK: - Initialization
    public init() {
        // Retrieve the global user defaults domain.
        let globalDomain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        
        // Initialize appearance properties.
        // Note: SLSGetAppearanceThemeLegacy/SLSGetAppearanceThemeSwitchesAutomatically are private APIs.
        let isDarkTheme = (SLSGetAppearanceThemeLegacy() == .dark)
        let isAutoTheme = (SLSGetAppearanceThemeSwitchesAutomatically() == 1)
        if isDarkTheme { self.theme = .dark }
        else if isAutoTheme { self.theme = .auto }
        else { self.theme = .light }
        
        let currentAccentColorValue = NSColorGetUserAccentColor()
        self.accentColor = AccentType(rawValue: Int(currentAccentColorValue)) ?? .multicolor
        if currentAccentColorValue == -1 { self.accentColor = .gray }
        if currentAccentColorValue == -2 { self.accentColor = .multicolor }
        
        let currentHighlightColorValue = NSColorGetUserHighlightColor()
        self.highlightColor = HighlightType(rawValue: Int(currentHighlightColorValue)) ?? .accentcolor
        if currentHighlightColorValue == -2 { self.highlightColor = .gray }
        if currentHighlightColorValue == -1 { self.highlightColor = .accentcolor }
        
        self.sidebarSize = (globalDomain?[PaneDefaults.sidebarSizeKey] as? Int) ?? 2
        self.wallpaperTinting = !(globalDomain?[PaneDefaults.wallpaperTintingKey] as? Bool ?? false)
        let rawScrollbarValue = (globalDomain?[PaneDefaults.showScrollbarKey] as? String)
        self.showScrollbars = ShowScrollbarType(rawValue: rawScrollbarValue ?? "") ?? .auto
        
        // Initialize window & document properties.
        self.windowQuit = (globalDomain?[PaneDefaults.windowQuitKey] as? Bool) ?? false
        self.closeAlwaysConfirms = (globalDomain?[PaneDefaults.closeAlwaysConfirmsKey] as? Bool) ?? false
        let rawTabbingModeValue = (globalDomain?[PaneDefaults.tabbingModeKey] as? String)
        self.tabbingMode = TabbingModeType(rawValue: rawTabbingModeValue ?? "") ?? .fullscreen
        self.jumpPage = (globalDomain?[PaneDefaults.jumpPageKey] as? Bool) ?? false
        self.recentItemsCount = (globalDomain?[PaneDefaults.recentItemsKey] as? Int) ?? 10
        
        // Initialize Handoff property.
        let isHandoffEnabled = (globalDomain?[PaneDefaults.handoffEnabledKey] as? Bool) ?? true
        let isActivityContinuationEnabled = (globalDomain?[PaneDefaults.handoffActivityContinuationKey] as? Bool) ?? true
        self.handoffEnabled = isHandoffEnabled && isActivityContinuationEnabled
        
        // Load web browsers and setup XPC connection.
        loadBrowsers()
        setupHelperConnection()
    }
    
    // MARK: - XPC Setup
    
    // Establishes and manages the connection to the XPC helper tool.
    private func setupHelperConnection() {
        // The service name MUST match the Bundle Identifier of your LegacyPreferencesHelper target.
        helperConnection = NSXPCConnection(serviceName: "com.acer51-doctom.LegacyPreferencesHelper")
        // Define the protocol interface for communication.
        helperConnection?.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
        
        // Handlers for connection invalidation and interruption to ensure robustness.
        helperConnection?.invalidationHandler = { [weak self] in
            NSLog("XPC connection invalidated. Attempting to reconnect...")
            self?.helperConnection = nil
            self?.setupHelperConnection() // Attempt to re-establish connection
        }
        helperConnection?.interruptionHandler = { [weak self] in
            NSLog("XPC connection interrupted. Attempting to reconnect...")
            self?.helperConnection = nil
            self?.setupHelperConnection() // Attempt to re-establish connection
        }
        
        helperConnection?.resume() // Activate the connection.
    }
    
    // MARK: - Preference Setters
    
    // Sets the system interface style (Light, Dark, or Auto).
    func setInterfaceStyle(_ newTheme: ThemeType) {
        self.theme = newTheme // Update published property immediately
        
        let isDark = (newTheme == .dark)
        let isAuto = (newTheme == .auto)
        
        SLSSetAppearanceThemeLegacy(isDark ? .dark : .light)
        SLSSetAppearanceThemeSwitchesAutomatically(isAuto ? 1 : 0)
        
        Logger.log("Interface style set to: \(newTheme.rawValue)", class: Self.self)
    }
    
    // Sets the system accent color.
    func setAccentColor(_ newAccentColor: AccentType) {
        self.accentColor = newAccentColor // Update published property
        
        // Automatically set highlight color to match accent color, as is typical macOS behavior.
        // Ensure the raw values align between AccentType and HighlightType.
        self.setHighlightColor(HighlightType(rawValue: newAccentColor.rawValue) ?? .accentcolor)
        
        // Note: NSColorSetUserAccentColor is a private API.
        switch newAccentColor {
        case .multicolor: NSColorSetUserAccentColor(-2)
        case .gray: NSColorSetUserAccentColor(-1)
        default: NSColorSetUserAccentColor(Int32(newAccentColor.rawValue))
        }
        Logger.log("Accent color set to: \(newAccentColor)", class: Self.self)
    }
    
    // Sets the system highlight color.
    func setHighlightColor(_ newHighlightColor: HighlightType) {
        self.highlightColor = newHighlightColor // Update published property
        
        // Note: NSColorSetUserHighlightColor is a private API.
        switch newHighlightColor {
        case .accentcolor: NSColorSetUserHighlightColor(-1)
        case .gray: NSColorSetUserHighlightColor(-2)
        default: NSColorSetUserHighlightColor(Int32(newHighlightColor.rawValue))
        }
        Logger.log("Highlight color set to: \(newHighlightColor)", class: Self.self)
    }
    
    // Sets the sidebar icon size.
    func setSidebarSize(_ newSize: Int) {
        self.sidebarSize = newSize // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting sidebar size.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.sidebarSizeKey] = newSize
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.sidebarSizeNotifKey), object: nil)
        Logger.log("Sidebar size set to: \(newSize)", class: Self.self)
    }
    
    // Sets whether wallpaper tinting is allowed in windows.
    func setWallpaperTinting(_ enabled: Bool) {
        self.wallpaperTinting = enabled // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting wallpaper tinting.", isError: true, class: Self.self)
            return
        }
        // `enabled` (UI toggle) is inverse of `AppleReduceDesktopTinting` (preference key)
        domain[PaneDefaults.wallpaperTintingKey] = !enabled
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.wallpaperTintingNotifKey), object: nil)
        Logger.log("Wallpaper tinting enabled: \(enabled)", class: Self.self)
    }
    
    // Sets the scrollbar visibility behavior.
    func setShowScrollbars(_ newType: ShowScrollbarType) {
        self.showScrollbars = newType // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting scrollbar visibility.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.showScrollbarKey] = newType.rawValue
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        DistributedNotificationCenter.default().post(name: .init(PaneDefaults.showScrollbarNotifKey), object: nil)
        Logger.log("Show scrollbars set to: \(newType.rawValue)", class: Self.self)
    }
    
    // Sets the window tabbing mode.
    func setTabbingMode(_ newMode: TabbingModeType) {
        self.tabbingMode = newMode // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting tabbing mode.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.tabbingModeKey] = newMode.rawValue
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("Tabbing mode set to: \(newMode.rawValue)", class: Self.self)
    }
    
    // Sets whether windows are closed when quitting an app.
    func setWindowQuitBehavior(_ closesWindows: Bool) {
        self.windowQuit = closesWindows // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting window quit behavior.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.windowQuitKey] = closesWindows
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("Close windows on quit set to: \(closesWindows)", class: Self.self)
    }
    
    // Sets whether closing documents always confirms changes.
    func setCloseAlwaysConfirms(_ confirms: Bool) {
        self.closeAlwaysConfirms = confirms // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting close always confirms.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.closeAlwaysConfirmsKey] = confirms
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("Close always confirms set to: \(confirms)", class: Self.self)
    }
    
    // Sets the "Click in the scroll bar to:" behavior.
    func setJumpPageBehavior(_ jumpsToClickedSpot: Bool) {
        self.jumpPage = jumpsToClickedSpot // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting jump page behavior.", isError: true, class: Self.self)
            return
        }
        domain[PaneDefaults.jumpPageKey] = jumpsToClickedSpot
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("Jump page behavior set to: \(jumpsToClickedSpot)", class: Self.self)
    }
    
    // Sets the Handoff enabled state.
    func setHandoffEnabled(_ enabled: Bool) {
        self.handoffEnabled = enabled // Update published property
        
        guard var domain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) else {
            Logger.log("Failed to get global domain for setting Handoff enabled state.", isError: true, class: Self.self)
            return
        }
        // Both keys need to be set for Handoff.
        domain[PaneDefaults.handoffEnabledKey] = enabled
        domain[PaneDefaults.handoffActivityContinuationKey] = enabled
        UserDefaults.standard.setPersistentDomain(domain, forName: UserDefaults.globalDomain)
        Logger.log("Handoff enabled set to: \(enabled)", class: Self.self)
    }
    
    // Sets the number of recent items using the XPC helper tool.
    func setRecentItemsCount(_ count: Int) {
        self.recentItemsCount = count // Update published property immediately for UI responsiveness
        
        // Get a proxy to the helper tool.
        guard let helper = helperConnection?.remoteObjectProxyWithErrorHandler({ error in
            NSLog("XPC connection error for setRecentItemsCount: \(error.localizedDescription)")
            // Potentially inform the user that the helper tool is unavailable or failed.
        }) as? HelperToolProtocol else {
            NSLog("Failed to get remote object proxy for HelperToolProtocol.")
            return
        }
        
        // Call the method on the helper tool.
        helper.setRecentItemsCount(count: count) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    NSLog("Recent Items Count successfully requested from helper: \(count)")
                    // After successful request, re-read the value to ensure UI is in sync
                    // with the actual system setting (which might take a moment to apply).
                    if let globalDomain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) {
                        self?.recentItemsCount = (globalDomain[PaneDefaults.recentItemsKey] as? Int) ?? 10
                    }
                } else {
                    NSLog("Failed to set Recent Items Count via helper.")
                    // Revert UI to previous state or show error message if the operation failed.
                    if let globalDomain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) {
                        self?.recentItemsCount = (globalDomain[PaneDefaults.recentItemsKey] as? Int) ?? 10
                    }
                }
            }
        }
    }
    
    // Loads all available web browsers and identifies the current default.
    func loadBrowsers() {
        let httpHandlers = LSCopyAllHandlersForURLScheme("http" as CFString)?.takeRetainedValue() as? [String] ?? []
        let httpsHandlers = LSCopyAllHandlersForURLScheme("https" as CFString)?.takeRetainedValue() as? [String] ?? []
        
        let allHandlers = Set(httpHandlers + httpsHandlers)
        let filteredHandlers = allHandlers.filter { PaneDefaults.popularBrowserBundleIDs.contains($0) }
        
        var browsers: [BrowserInfo] = []
        for bundleID in filteredHandlers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
               let bundle = Bundle(url: url),
               let appName = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
                
                let appIcon = NSWorkspace.shared.icon(forFile: url.path)
                appIcon.size = NSSize(width: 32, height: 32)
                
                browsers.append(BrowserInfo(id: bundleID, name: appName, icon: appIcon))
            }
        }
        
        self.availableBrowsers = browsers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        if let defaultHTTPHandler = LSCopyDefaultHandlerForURLScheme("http" as CFString)?.takeRetainedValue() as? String {
            self.defaultBrowserIdentifier = defaultHTTPHandler
        } else {
            self.defaultBrowserIdentifier = ""
        }
        
        Logger.log("Loaded \(self.availableBrowsers.count) browsers. Default: \(self.defaultBrowserIdentifier)", class: Self.self)
    }
    
    // Sets the system's default web browser for HTTP and HTTPS schemes.
    func setDefaultWebBrowser(bundleIdentifier: String) {
        let httpScheme = "http" as CFString
        let httpsScheme = "https" as CFString
        
        let statusHTTP = LSSetDefaultHandlerForURLScheme(httpScheme, bundleIdentifier as CFString)
        let statusHTTPS = LSSetDefaultHandlerForURLScheme(httpsScheme, bundleIdentifier as CFString)
        
        if statusHTTP == noErr && statusHTTPS == noErr {
            Logger.log("Successfully set default browser to \(bundleIdentifier)", class: Self.self)
            self.defaultBrowserIdentifier = bundleIdentifier // Update published property
            DistributedNotificationCenter.default().post(name: .init("ApplePreferredBrowserChanged"), object: nil)
        } else {
            Logger.log("Failed to set default browser to \(bundleIdentifier). HTTP Status: \(statusHTTP), HTTPS Status: \(statusHTTPS)", isError: true, class: Self.self)
        }
    }
}
