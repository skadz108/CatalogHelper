//
//  IconTheming.swift
//  Accessible
//
//  Created by Skadz on 10/18/24.
//  Almost entirely skidded from SparseThemer.
//

import Foundation
import AssetCatalogWrapper

enum ImageError: Error {
    case invalidImageData
    case unableToGetCGImage
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let fileManager = FileManager.default
    
    // skidded from SparseThemer !!
    func replaceIcons(icon: URL, car: URL) throws -> URL {
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
        
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        let moddedCarName = car.deletingPathExtension().appendingPathExtension("themed.car")
        let themedCarURL = tempDirectory.appendingPathComponent(moddedCarName.lastPathComponent)
        try fileManager.copyItem(at: car, to: themedCarURL)
        
        let (catalog, renditionsRoot) = try AssetCatalogWrapper.shared.renditions(forCarArchive: themedCarURL)
        for rendition in renditionsRoot {
            let type = rendition.type
            guard type == .icon else { continue }
            let renditions = rendition.renditions
            for rend in renditions {
                do {
                    let imgData = try Data(contentsOf: icon)
                    
                    guard let dataProvider = CGDataProvider(data: imgData as CFData) else { throw ImageError.invalidImageData }
                    
                    guard let cgImage = CGImage(
                        pngDataProviderSource: dataProvider,
                        decode: nil,
                        shouldInterpolate: true,
                        intent: .defaultIntent
                    ) else { throw ImageError.unableToGetCGImage }
                    
                    try catalog.editItem(rend, fileURL: themedCarURL, to: .image(cgImage))
                    
                    return themedCarURL
                } catch {
                    print("Error processing image: \(error)")
                    throw error
                }
            }
        }
        
        return URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
    }
}
