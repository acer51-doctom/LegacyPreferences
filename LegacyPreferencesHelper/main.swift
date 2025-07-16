//
//  main.swift
//  LegacyPreferencesHelper
//
//  Created by acer51-doctom on 16/07/2025.
//

import Foundation
import AppKit // For NSWorkspace and other AppKit utilities if needed
import CoreServices // For LSSetDefaultHandlerForURLScheme if needed

// Implement the HelperToolProtocol.
// This class will handle requests from the main application.
class HelperTool: NSObject, HelperToolProtocol {

    /// Sets the number of recent items in macOS using the 'defaults write' command.
    /// This operation is performed with the helper tool's elevated privileges.
    /// - Parameters:
    ///   - count: The desired number of recent items.
    ///   - completion: A closure to be called upon completion, indicating success or failure.
    func setRecentItemsCount(count: Int, withReply completion: @escaping (Bool) -> Void) {
        let domain = "Apple Global Domain" // The domain for system-wide preferences
        let key = "AppleShowRecentItems"   // The key for recent items count

        // Construct the 'defaults write' command.
        // We use 'defaults' command-line tool as it's a reliable way to modify system preferences
        // from a privileged context, and it handles necessary notifications internally.
        let process = Process()
        process.launchPath = "/usr/bin/defaults"
        process.arguments = ["write", domain, key, "-int", "\(count)"]

        let pipe = Pipe()
        process.standardError = pipe // Capture error output

        do {
            try process.run()
            process.waitUntilExit()

            let status = process.terminationStatus
            if status == 0 {
                // Success
                NSLog("HelperTool: Successfully set Recent Items Count to \(count)")
                completion(true)
            } else {
                // Failure
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                NSLog("HelperTool: Failed to set Recent Items Count. Error: \(errorOutput) (Exit Status: \(status))")
                completion(false)
            }
        } catch {
            NSLog("HelperTool: Failed to run defaults command: \(error.localizedDescription)")
            completion(false)
        }
    }
}

// Set up the XPC listener.
// This is boilerplate code for an XPC Service.
class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Configure the connection to use the protocol defined earlier.
        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        let exportedObject = HelperTool()
        newConnection.exportedObject = exportedObject
        newConnection.resume() // Start the connection
        return true
    }
}

// Create the listener and set its delegate.
let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate

// Resume the listener to start accepting incoming connections.
listener.resume()

// Keep the process running indefinitely.
RunLoop.current.run()
