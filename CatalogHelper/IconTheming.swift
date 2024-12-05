//
//  IconTheming.swift
//  Accessible
//
//  Created by Skadz on 10/18/24.
//  Uses code from SparseThemer and OpenPicasso.
//

import Foundation
import AssetCatalogWrapper
import ZIPFoundation

enum ImageError: Error {
    case invalidImageData
    case unableToGetCGImage
}

var rawThemesDir: URL = {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("themes/")
}()
var originalIconsDir: URL = {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("catalogBackups/")
}()

class IconTheme: ObservableObject, Identifiable {
    var id = UUID()
    
    @Published var name: String
    @Published var iconCount: Int
    
    @Published var isSelected: Bool = false
    
    var url: URL {
        return rawThemesDir.appendingPathComponent(name)
    }
    
    init(name: String, iconCount: Int) {
        self.name = name
        self.iconCount = iconCount
    }
}

struct ThemedIcon: Codable {
    var appID: String
    var themeName: String
    
    func iconData() throws -> Data {
        let data = try Data(contentsOf: rawThemesDir.appendingPathComponent(themeName).appendingPathComponent(appID + ".png"))
        return data
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let fileManager = FileManager.default
    
    @Published var themes: [IconTheme] = []
    
    private func getThemes() -> [IconTheme] {
        return ((try? FileManager.default.contentsOfDirectory(at: rawThemesDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []).map { url in
            let theme = IconTheme(name: url.lastPathComponent, iconCount: 0)
            theme.iconCount = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).count) ?? 0
            return theme
        }
    }
    
    public func updateThemes() {
        themes = getThemes()
    }
    
    func deleteTheme(theme: IconTheme) throws {
        try fileManager.removeItem(at: theme.url)
        updateThemes()
    }
    
    func importAppList(appListURL: URL) {
        let appListPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("melatoninapplist")
        if fileManager.fileExists(atPath: appListPath.path) {
            do {
                try fileManager.removeItem(at: appListPath)
            } catch {
                print("[ThemeManager] Failed to remove old app list!")
                return
            }
        }
        
        let appListAccessing = appListURL.startAccessingSecurityScopedResource()
        defer {
            if appListAccessing {
                appListURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            try fileManager.copyItem(at: appListURL, to: appListPath)
            UserDefaults.standard.set(appListPath, forKey: "appListPath")
        } catch {
            print("[ThemeManager] Failed to import melatoninapplist file!")
            return
        }
    }
    
    public func importTheme(iconBundle: URL) throws {
        let iconBundleAccessing = iconBundle.startAccessingSecurityScopedResource()
        defer {
            if iconBundleAccessing {
                iconBundle.stopAccessingSecurityScopedResource()
            }
        }
        
        let themeName = iconBundle.deletingPathExtension().lastPathComponent
        try? fileManager.createDirectory(at: rawThemesDir, withIntermediateDirectories: true)
        let themeURL = rawThemesDir.appendingPathComponent(themeName)
        
        try fileManager.createDirectory(at: themeURL, withIntermediateDirectories: true)
        
        for icon in (try? fileManager.contentsOfDirectory(at: iconBundle, includingPropertiesForKeys: nil)) ?? [] {
            guard !icon.lastPathComponent.contains(".DS_Store") else { continue }
            try? fileManager.copyItem(at: icon, to: themeURL.appendingPathComponent(getAppIDFromIconFile(icon) + ".png"))
        }
        updateThemes()
    }
    
    private func getAppIDFromIconFile(_ url: URL) -> String {
        return url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "-large", with: "")
    }
    
    func getAppIcons(for appIDs: [String], theme: IconTheme) -> [UIImage?] {
        var images: [UIImage?] = []
        guard let iconImages = try? FileManager.default.contentsOfDirectory(at: theme.url, includingPropertiesForKeys: nil) else { return [] }
        for iconImage in iconImages {
            let appID = getAppIDFromIconFile(iconImage)
            guard appIDs.contains(appID) else { continue }
            let themedIcon = ThemedIcon(appID: appID, themeName: theme.name)
            if let iconData = try? themedIcon.iconData() {
                images.append(UIImage(data: iconData))
            } else {
                images.append(nil)
            }
        }
        return images
    }
    
    // (partially) skidded from SparseThemer
    func replaceIcons(icon: URL, car: URL) throws {
        let iconAccessing = icon.startAccessingSecurityScopedResource()
        defer {
            if iconAccessing {
                icon.stopAccessingSecurityScopedResource()
            }
        }
        let carAccessing = car.startAccessingSecurityScopedResource()
        defer {
            if carAccessing {
                car.stopAccessingSecurityScopedResource()
            }
        }
        
        try? fileManager.createDirectory(at: originalIconsDir, withIntermediateDirectories: true)
        let moddedCarURL = originalIconsDir.appendingPathComponent(car.lastPathComponent)
        let moddedIconURL = originalIconsDir.appendingPathComponent(getAppIDFromIconFile(icon))
        
        do {
            if fileManager.fileExists(atPath: moddedCarURL.path()) {
                try? fileManager.removeItem(at: moddedCarURL)
            }
            try fileManager.copyItem(at: car, to: moddedCarURL)
            if fileManager.fileExists(atPath: moddedIconURL.path()) {
                try? fileManager.removeItem(at: moddedIconURL)
            }
            try fileManager.copyItem(at: icon, to: moddedIconURL)
        } catch {
            print(error.localizedDescription)
            throw error
        }
        
        let (catalog, renditionsRoot) = try AssetCatalogWrapper.shared.renditions(forCarArchive: moddedCarURL)
        for rendition in renditionsRoot {
            let type = rendition.type
            guard type == .icon else { continue }
            let renditions = rendition.renditions
            for rend in renditions {
                do {
                    let imgData = try Data(contentsOf: moddedIconURL)
                    
                    guard let dataProvider = CGDataProvider(data: imgData as CFData) else { throw ImageError.invalidImageData }
                    
                    guard let cgImage = CGImage(
                        pngDataProviderSource: dataProvider,
                        decode: nil,
                        shouldInterpolate: true,
                        intent: .defaultIntent
                    ) else { throw ImageError.unableToGetCGImage }
                    
                    try catalog.editItem(rend, fileURL: moddedCarURL, to: .image(cgImage))
                } catch {
                    print("Error processing image: \(error)")
                }
            }
        }
    }
}
