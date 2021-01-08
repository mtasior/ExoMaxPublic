//
//  ExoMaxControllerApp.swift
//  Shared
//
//  Created by Michael Tasior on 25.12.20.
//

import SwiftUI

@main
struct ExoMaxControllerApp: App {
    @StateObject var model = ControllerModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        #if os(iOS) // Due to some reason, the scenePhase is not recognized with the window group for all OS.
            WindowGroup {
                ContentView()
                    .environmentObject(model)
                    .padding()
            }
            .onChange(of: scenePhase) { newScenePhase in reactToScenePhase(newScenePhase: newScenePhase) }
        #elseif os(macOS)
            WindowGroup {
                ContentView()
                    .environmentObject(model)
                    .padding()
                    .onChange(of: scenePhase) { newScenePhase in reactToScenePhase(newScenePhase: newScenePhase) }
            }
        #else
            WindowGroup {
                ContentView()
                    .edgesIgnoringSafeArea(.all)
                    .environmentObject(model)
                    .onChange(of: scenePhase) { newScenePhase in reactToScenePhase(newScenePhase: newScenePhase) }
            }
        #endif
    }

    private func reactToScenePhase(newScenePhase: ScenePhase) {
        switch newScenePhase {
        case .active:
            print("App is active")
            model.setup()
        case .inactive:
            print("App is inactive")
            model.teardown()
        case .background:
            print("App is in background")
            model.teardown()
        @unknown default:
            print("Unexpected new value.")
        }
    }
}
