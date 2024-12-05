//
//  CatalogHelperApp.swift
//  CatalogHelper
//
//  Created by Skadz on 12/4/24.
//

import SwiftUI

@main
struct CatalogHelperApp: App {
    // Fix file picker (brought to you by Nugget-Mobile)
    init() {
        if let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, Selector(("fix_initForOpeningContentTypes:asCopy:"))), let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:))) {
            method_exchangeImplementations(origMethod, fixMethod)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
