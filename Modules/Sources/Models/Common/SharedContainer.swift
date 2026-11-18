//
//  SharedContainer.swift
//  ForPDA
//
//  Resolves the App Group container in a way that survives sideloading.
//

import Foundation

public enum SharedContainer {

    /// App Group identifier the app is built with.
    public static let defaultGroupIdentifier = "group.com.subvert.forpda"

    /// Directory shared between the app and its extensions.
    ///
    /// Sideloading tools (SideStore / AltStore) re-sign the app with a different
    /// App Group identifier and list the new ones under `ALTAppGroups` in Info.plist.
    /// If no App Group is available at all, falls back to the app's own
    /// Application Support directory instead of crashing.
    public static let url: URL = {
        let fileManager = FileManager.default

        for identifier in candidateGroupIdentifiers {
            if let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                return url
            }
        }

        let fallback = URL.applicationSupportDirectory.appending(component: "SharedContainer", directoryHint: .isDirectory)
        try? fileManager.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }()

    private static var candidateGroupIdentifiers: [String] {
        var identifiers: [String] = []
        // Extensions have their own Info.plist, so check the host app's bundle as well.
        for bundle in [Bundle.main, hostAppBundle].compactMap({ $0 }) {
            if let groups = bundle.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] {
                identifiers.append(contentsOf: groups)
            }
        }
        identifiers.append(defaultGroupIdentifier)
        var seen = Set<String>()
        return identifiers.filter { seen.insert($0).inserted }
    }

    private static var hostAppBundle: Bundle? {
        let url = Bundle.main.bundleURL
        guard url.pathExtension == "appex" else { return nil }
        // .../ForPDA.app/PlugIns/NSE.appex -> .../ForPDA.app
        return Bundle(url: url.deletingLastPathComponent().deletingLastPathComponent())
    }
}
