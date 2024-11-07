//
//  VoxiApp.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

@main
struct VoxiApp: App {
    
    // Se crea una instancia de SpeechViewModel como un @StateObject,
    // lo que significa que es el propietario del ciclo de vida de este objeto
    // y será la fuente de verdad para cualquier vista que lo observe.
    @StateObject private var viewModel = SpeechViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                
        }
    }
}
