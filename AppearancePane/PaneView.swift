//
//  PaneView.swift
//  AppearancePane
//
//  Created by dehydratedpotato on 6/5/23.
//  Maintained by acer51-doctom since 14/07/2025 (DD-MM-YYYY)
//

import SwiftUI
import CoreServices // Required for LaunchServices APIs for default web browser functionality
import Combine // Required for .onReceive
import AppKit // Required for NSImage used in BrowserRow

// Assuming PaneConstants, PaneDefaults, and Logger are defined in their respective files
// and are accessible from this file.

public struct PaneView: View {
    // State variables to hold the current settings, bound to UI controls.
    @State private var sidebarSize: Int
    @State private var showScrollbars: PaneDefaults.ShowScrollbarType
    @State private var tinting: Bool
    @State private var windowCloseQuit: Bool
    @State private var windowCloseConfirm: Bool
    @State private var tabbingMode: PaneDefaults.TabbingModeType
    @State private var jumpPage: Bool
    // Removed: @State private var recentItemsCount: Int
    
    // The ObservedObject to access and modify system preferences.
    @ObservedObject private var defaults: PaneDefaults = PaneDefaults()
    
    // State for the default web browser picker.
    @State private var selectedBrowserIdentifier: String = ""
    
    // Initializer to set initial state from PaneDefaults.
    public init() {
        let defaults = PaneDefaults()
        self._defaults = ObservedObject(wrappedValue: defaults) // Initialize ObservedObject
        
        // Set initial state values from PaneDefaults.
        self._tinting = State(initialValue: defaults.startWallpaperTinting)
        self._sidebarSize = State(initialValue: defaults.startSidebarSize)
        self._showScrollbars = State(initialValue: defaults.startShowScrollbars)
        self._windowCloseQuit = State(initialValue: defaults.startWindowQuit)
        self._windowCloseConfirm = State(initialValue: defaults.startcloseAlwaysConfirms)
        self._tabbingMode = State(initialValue: defaults.startTabbingMode)
        self._jumpPage = State(initialValue: defaults.startJumpPage)
        // Removed: self._recentItemsCount = State(initialValue: defaults.startRecentItemsCount)
    }
    
    public var body: some View {
        VStack() {
            group1
            
            Divider().padding([.top, .bottom], 10)
            
            group2
            
            Divider().padding([.top, .bottom], 10)
            
            group3 // Default web browser group
            
            Divider().padding([.top, .bottom], 10)
            
            group4
            
            Spacer()
        }
        .frame(width: PaneConstants.paneWidth - (PaneConstants.panePadding * 2),
               height: PaneDefaults.paneHeight - (PaneConstants.panePadding * 2))
        .padding(PaneConstants.panePadding)
        .navigationTitle(PaneConstants.nameTable[PaneConstants.PaneType.appearance.rawValue])
        .onAppear {
            // Load browsers when the view appears.
            defaults.loadBrowsers()
        }
        // Use .onReceive to react to changes in availableBrowsers and defaultBrowserIdentifier
        // ensuring the picker's selection is valid once data is loaded.
        .onReceive(defaults.$availableBrowsers.combineLatest(defaults.$defaultBrowserIdentifier)) { (browsers, defaultId) in
            // Only update selectedBrowserIdentifier if browsers are available and a valid defaultId exists
            if !browsers.isEmpty {
                if browsers.contains(where: { $0.id == defaultId }) {
                    selectedBrowserIdentifier = defaultId
                } else {
                    // Fallback to the first browser if the default is not found (e.g., uninstalled)
                    selectedBrowserIdentifier = browsers.first?.id ?? ""
                }
            } else {
                // If no browsers are loaded yet, keep selection empty.
                selectedBrowserIdentifier = ""
            }
        }
    }
    
    @ViewBuilder private var group1: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing) {
                Text("Appearance:")
                    .frame(height: 46, alignment: .bottom)
                Text("Accent Color:")
                    .frame(height: 38, alignment: .bottom)
                Text("Highlight color:")
                    .frame(height: 44, alignment: .bottom)
                Text("Sidebar icon size:")
                    .frame(height: 22, alignment: .bottom)
            }
            .frame(width: PaneDefaults.labelColumnWidth, alignment: .trailing)
            
            VStack(alignment: .leading) {
                ThemePicker(selection: defaults.startTheme)
                    .environmentObject(defaults)
                
                AccentPicker(selection: defaults.startAccentColor)
                    .environmentObject(defaults)
                
                HighlightPicker(selection: defaults.startHighlightColor)
                    .frame(width: PaneDefaults.maximumPickerWidth)
                    .padding(.bottom, 2)
                    .environmentObject(defaults)
                
                // Simplified binding for sidebarSize
                Picker(selection: $sidebarSize, content: {
                    Text("Small").tag(1)
                    Text("Medium").tag(2)
                    Text("Large").tag(3)
                }, label: {
                    //
                })
                .frame(width: PaneDefaults.maximumPickerWidth)
                .onChange(of: sidebarSize) { newValue in
                    _ = defaults.setSidebarSize(toSize: newValue) // Use _ = to discard Bool return if not needed
                }
                
                // Simplified binding for tinting
                Toggle("Allow wallpaper tinting in windows", isOn: $tinting)
                    .onChange(of: tinting) { newValue in
                        _ = defaults.setWallpaperTint(to: newValue)
                    }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder private var group2: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing) {
                Text("Show scroll bars:")
                Text("Click in the scroll bar to:")
                    .frame(height: 64, alignment: .bottom)
            }
            .frame(width: PaneDefaults.labelColumnWidth, alignment: .trailing)
            
            VStack(alignment: .leading) {
                // Simplified binding for showScrollbars
                Picker(selection: $showScrollbars, content: {
                    Text("Automatically based on mouse or trackpad")
                        .tag(PaneDefaults.ShowScrollbarType.auto)
                    Text("When scrolling")
                        .tag(PaneDefaults.ShowScrollbarType.whenScrolling)
                    Text("Always")
                        .tag(PaneDefaults.ShowScrollbarType.always)
                }, label: {
                    //
                })
                .pickerStyle(.radioGroup)
                .padding(.bottom, 10)
                .onChange(of: showScrollbars) { newValue in
                    _ = defaults.setShowScrollbars(to: newValue)
                }
                
                // Simplified binding for jumpPage
                Picker(selection: $jumpPage, content: {
                    Text("Jump to the next page").tag(false)
                    Text("Jump to the spot that's clicked").tag(true)
                }, label: {
                    //
                })
                .pickerStyle(.radioGroup)
                .onChange(of: jumpPage) { newValue in
                    _ = defaults.setBool(for: PaneDefaults.jumpPageKey, to: newValue)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder private var group3: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing) {
                Text("Default web browser:")
            }
            .frame(width: PaneDefaults.labelColumnWidth, alignment: .trailing)
            
            // Default web browser picker implementation
            ZStack { // Use ZStack to overlay loading text
                Picker(selection: $selectedBrowserIdentifier, content: {
                    // Always iterate over availableBrowsers.
                    // The .onReceive modifier handles setting selectedBrowserIdentifier correctly.
                    ForEach(defaults.availableBrowsers) { browser in
                        BrowserRow(browser: browser)
                            .tag(browser.id)
                    }
                }, label: {
                    // Label is empty as it's defined by the Text("Default web browser:")
                })
                .frame(width: PaneDefaults.maximumPickerWidth)
                .onChange(of: selectedBrowserIdentifier) { newIdentifier in
                    // Only attempt to set if a valid browser is selected (i.e., not the "Loading..." placeholder)
                    if !newIdentifier.isEmpty {
                        defaults.setDefaultWebBrowser(bundleIdentifier: newIdentifier)
                    }
                }
                // Hide the picker if no browsers are loaded to prevent empty picker appearance
                .opacity(defaults.availableBrowsers.isEmpty ? 0 : 1)

                // Show loading text if no browsers are available
                if defaults.availableBrowsers.isEmpty {
                    Text("Loading browsers...")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.2)))
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder private var group4: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing) {
                Text("Prefer tabs:")
                Text("Recent items:")
                    .frame(height: 88, alignment: .bottom)
            }
            .frame(width: PaneDefaults.labelColumnWidth, alignment: .trailing)
            
            VStack(alignment: .leading) {
                HStack {
                    // Simplified binding for tabbingMode
                    Picker(selection: $tabbingMode, content: {
                        Text("in full screen").tag(PaneDefaults.TabbingModeType.fullscreen)
                        Text("always").tag(PaneDefaults.TabbingModeType.always)
                        Text("never").tag(PaneDefaults.TabbingModeType.never)
                    }, label: {
                        //
                    })
                    .frame(width: 106)
                    .onChange(of: tabbingMode) { newValue in
                        _ = defaults.setTabbingMode(to: newValue)
                    }
                    
                    Text("when opening documents")
                }
                
                // Simplified binding for windowCloseConfirm
                Toggle("Ask to keep changes when closing documents", isOn: $windowCloseConfirm)
                    .onChange(of: windowCloseConfirm) { newValue in
                        _ = defaults.setBool(for: PaneDefaults.closeAlwaysConfirms, to: newValue)
                    }
                
                // Simplified binding for windowCloseQuit
                Toggle("Close windows when quitting an app", isOn: $windowCloseQuit)
                    .onChange(of: windowCloseQuit) { newValue in
                        _ = defaults.setBool(for: PaneDefaults.windowQuitKey, to: newValue)
                    }
                
                Text("When selected, open documents and windows will not be restored\nwhen you re-open an app.")
                    .font(.caption)
                    .padding(.leading, 20)
                
                // Reverted Recent Items Picker to disabled state
                HStack {
                    Picker(selection: .constant(0), content: {
                        // Text("10").tag(0) // Example placeholder
                    }, label: {
                        //
                    })
                    .frame(width: 65)
                    
                    Text("Document, Apps, and Servers")
                }
                .disabled(true) // Reverted to disabled
                
                // TODO: Support toggling handoff
                Toggle("Allow Handoff between this Mac and your iCloud devices", isOn: .constant(true))
                    .disabled(true) // Still disabled as no logic is implemented yet
            }
            
            Spacer()
        }
    }
}

// MARK: - Private Helper Views

// A view for displaying a single theme option (Light, Dark, Auto).
private struct ThemePicker: View {
    @State var selection: PaneDefaults.ThemeType
    @EnvironmentObject var defaults: PaneDefaults
    
    private let themes: [PaneDefaults.Theme] = [
        .init(id: .light, hint: "Use a light appearance for buttons, menus, and windows."),
        .init(id: .dark, hint:"Use a dark appearance for buttons, menus, and windows."),
        .init(id: .auto, hint: "Automatically adjusts the appearance of for buttons, menus, and windows throughout the day.")
    ]
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(themes) { theme in
                let id = theme.id
                let selected = selection == id
                
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .frame(width: 71, height: 48)
                            .foregroundColor(selected ? .accentColor : .clear)
                        
                        // Image for theme preview (e.g., AppearanceLight_Normal)
                        Image("Appearance\(id.rawValue)_Normal", bundle: PaneDefaults.bundle)
                            .frame(width: 67, height: 44)
                            .shadow(color: selected ? .clear : .black.opacity(0.4), radius: 1, y: 1)
                        
                        // Apply accent color mask for non-auto themes
                        if (id != .auto) {
                            Color.accentColor
                                .frame(width: 67, height: 44)
                                .mask(
                                    Image("selectionColor_mask_Normal", bundle: PaneDefaults.bundle)
                                        .frame(width: 67, height: 44)
                                )
                        } else {
                            // Apply accent color mask for auto theme
                            Color.accentColor
                                .frame(width: 67, height: 44)
                                .mask(
                                    Image("selectionColor_mask-auto_Normal", bundle: PaneDefaults.bundle)
                                        .frame(width: 67, height: 44)
                                )
                        }
                    }
                    
                    Text(id.rawValue)
                }
                .help(theme.hint)
                .onTapGesture {
                    selection = id
                    defaults.setInterfaceStyle(isDark: id == .dark, isAuto: id == .auto)
                }
            }
        }
    }
}

// A view for displaying accent color options.
private struct AccentPicker: View {
    @State var selection: PaneDefaults.AccentType
    @EnvironmentObject var defaults: PaneDefaults
    
    private let accents: [PaneDefaults.Accent] = [
        .init(id: .multicolor, color: .teal), // Teal is just a placeholder visual for multicolor wheel
        .init(id: .blue, color: .blue),
        .init(id: .purple, color: .purple),
        .init(id: .pink, color: .pink),
        .init(id: .red, color: .red),
        .init(id: .orange, color: .orange),
        .init(id: .yellow, color: .yellow),
        .init(id: .green, color: .green),
        .init(id: .gray, color: .gray),
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                ForEach(accents) { accent in
                    let id = accent.id
                    
                    ZStack {
                        if accent.id != .multicolor {
                            Circle()
                                .foregroundColor(accent.color)
                        } else {
                            // Image for multicolor accent wheel
                            Image("MuticolorAccentWheel", bundle: PaneDefaults.bundle)
                                .resizable()
                                .mask(Circle())
                        }
                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.45), style: .init(lineWidth: 1))
                        
                        if selection == id {
                            Circle()
                                .foregroundColor(.white)
                                .padding(5)
                        }
                    }
                    .frame(width: 16, height: 16)
                    .help( PaneDefaults.accentTypeNameTable[ id.rawValue ])
                    .onTapGesture {
                        selection = id
                        defaults.setAccentColor(toType: id)
                    }
                }
            }
            
            Text(PaneDefaults.accentTypeNameTable[ selection.rawValue ])
                .foregroundColor(.secondary.opacity(0.75))
        }
    }
}

// A view for displaying highlight color options.
private struct HighlightPicker: View {
    @State var selection: PaneDefaults.HighlightType
    @EnvironmentObject var defaults: PaneDefaults
    
    private let highlights: [PaneDefaults.HighlightType] = [
        .accentcolor,
        .blue,
        .purple,
        .pink,
        .red,
        .orange,
        .yellow,
        .green,
        .gray
    ]
    
    var body: some View {
        Picker(selection: $selection, content: { // Changed to $selection for direct binding
            ForEach(highlights, id: \.self) { highlight in
                let raw = highlight.rawValue
                
                HStack {
                    // Image for highlight rectangle preview
                    Image("HighlightRect_\(raw)", bundle: PaneDefaults.bundle)
                        .opacity(0.7)
                    
                    Text(PaneDefaults.highlightTypeNameTable[raw])
                }
                .tag(highlight) // Tag with the enum case itself
            }
        }, label: {
            //
        })
        .onChange(of: selection) { newValue in // Added onChange to trigger setter
            defaults.setHighlightColor(toType: newValue)
        }
    }
}

// A helper view to display a browser's icon and name in the picker.
private struct BrowserRow: View {
    let browser: PaneDefaults.BrowserInfo
    
    var body: some View {
        HStack {
            if let icon = browser.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20) // Adjust size as needed
            } else {
                Image(systemName: "globe") // Fallback icon
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            Text(browser.name)
        }
    }
}

struct PaneView_Previews: PreviewProvider {
    static var previews: some View {
        PaneView()
    }
}
