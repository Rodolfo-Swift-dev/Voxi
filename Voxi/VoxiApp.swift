//
//  VoxiApp.swift
//  Voxi
//
//  Created by Rodolfo Gonzalez on 10-10-24.
//

import SwiftUI

@main
struct VoxiApp: App {
    @StateObject private var speechViewModel = SpeechViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speechViewModel)
        }
    }
}
