//
//  ContentView.swift
//  CatalogHelper
//
//  Created by Skadz on 12/4/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // Asset catalog importer stuff
    @State private var isCatalogImporterPresented: Bool = false
    @State private var selectedCatalogURL: URL?
    
    // Icon png importer stuff
    @State private var isPNGImporterPresented: Bool = false
    @State private var selectedPNGURL: URL?
    
    @State private var hasThemedCatalog: Bool = false
    @State private var themedCarURL: URL = .init(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
    
    @StateObject var themeManager = ThemeManager.shared
    
    @State private var showingInfoSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Files"), content: {
                        Button(action: {
                            isCatalogImporterPresented = true
                        }, label: {
                            if selectedCatalogURL != nil  {
                                Label("Asset catalog imported!", systemImage: "checkmark")
                            } else {
                                Label("Import asset catalog", systemImage: "books.vertical")
                            }
                        })
                        .fileImporter(
                            isPresented: $isCatalogImporterPresented,
                            allowedContentTypes: [UTType(filenameExtension: "car")!]
                        ) { result in
                            switch result {
                            case .success(let file):
                                selectedCatalogURL = file.absoluteURL
                            case .failure(let error):
                                print(error.localizedDescription)
                                print("There was an error while importing the asset catalog. Check Xcode logs for more details.")
                            }
                        }
                        Button(action: {
                            isPNGImporterPresented = true
                        }, label: {
                            if selectedPNGURL != nil  {
                                Label("Custom icon imported!", systemImage: "checkmark")
                            } else {
                                Label("Import custom icon", systemImage: "app.dashed")
                            }
                        })
                        .fileImporter(
                            isPresented: $isPNGImporterPresented,
                            allowedContentTypes: [.png]
                        ) { result in
                            switch result {
                            case .success(let file):
                                selectedPNGURL = file.absoluteURL
                            case .failure(let error):
                                print(error.localizedDescription)
                                print("There was an error while importing the icon. Check Xcode logs for more details.")
                            }
                        }
                        HStack {
                            Spacer()
                            Button(action: {
                                do {
                                    themedCarURL = try themeManager.replaceIcons(icon: selectedPNGURL!, car: selectedCatalogURL!)
                                    Haptic.shared.notify(.success)
                                    hasThemedCatalog = true
                                } catch {
                                    print(error.localizedDescription)
                                    hasThemedCatalog = false
                                    Haptic.shared.notify(.error)
                                    UIApplication.shared.alert(title: "Icon Theming error!", body: "An error occurred while theming the asset catalog: \(error.localizedDescription)")
                                }
                            }) {
                                Text("Theme asset catalog")
                                    .padding(6)
                                    .frame(minWidth: 100)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .background(Color.accentColor)
                                    .foregroundStyle(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .disabled(selectedCatalogURL == nil || selectedPNGURL == nil)
                            }
                            Spacer()
                        }
                    })
                    
                    if hasThemedCatalog {
                        Section(header: Text("Output catalog"), content: {
                            ShareLink(item: themedCarURL)
                        })
                    }
                }
            }
            .navigationTitle("CatalogHelper")
//            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingInfoSheet, content: {
                InfoView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingInfoSheet.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }
}

struct IconView: View {
    var body: some View {
        ZStack {
            Image(systemName: "app.fill")
                .font(.system(size: CGFloat(32)))
                .foregroundColor(.accent)
            Image(systemName: "books.vertical")
                .font(.system(size: CGFloat(16)))
                .foregroundColor(.white)
        }
    }
}

struct InfoView: View {
    var isDebug: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
    
    var body: some View {
        Spacer()
        HStack {
            Spacer()
            VStack {
                Text("CatalogHelper")
                    .font(.system(size: 45, weight: .medium, design: .rounded))
                    .lineLimit(1)
                Text("Brought to you by Skadz")
                    .font(.system(size: 20, weight: .regular))
                    .lineLimit(1)
                Text("\nSpecial thanks to:\nhaxi0    hrtowii    Duy Tran\njailbreak.party  NSAntoine")
                    .font(.system(size: 12.5, weight: .light))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        
        Spacer()
        
        Text("[View on GitHub](https://github.com/skadz108/CatalogHelper)")
        Text("[Check out SkadzThemer!](https://github.com/skadz108/SkadzThemer)")
        
        Spacer()
        
        Text("Version 1.0 (\(isDebug))")
            .font(.footnote)
        
        Spacer()
    }
}

#Preview {
    ContentView()
}
