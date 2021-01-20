//
//  KeyboardHandler.swift
//  ExoMaxController (macOS)
//
//  Created by Michael Tasior on 17.01.21.
//

import SwiftUI

final class KeyboardHandler: NSViewRepresentable {
    let model: ControllerModel

    init(model: ControllerModel) {
        self.model = model
    }

    class KeyView: NSView {
        var model: ControllerModel?

        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            if event.characters == "w" { model?.increaseSpeed() }
            if event.characters == "s" { model?.decreaseSpeed() }
            if event.characters == " " { model?.stop() }
            if event.characters == "a" { model?.movementControl(x: -0.5, y: 0.0) }
            if event.characters == "d" { model?.movementControl(x: 0.5, y: 0.0) }
            if event.characters == "c" { model?.resetCamera() }
            if event.characters == "e" { model?.camToRightWheel() }
            if event.characters == "q" { model?.camToLeftWheel() }
            if event.characters == "v" { model?.camToCenterLow() }
            if event.characters == "b" { model?.camToCenterHigh() }
            if event.characters == "r" { model?.changeSteeringMode(to: .ACKERMANN) }
            if event.characters == "f" { model?.changeSteeringMode(to: .SPOT_TURN) }
            if event.characters == "t" { model?.changeSteeringMode(to: .CRABBING) }
            if event.keyCode == 126 { model?.moveCamVertically(amount: 1.0) }
            if event.keyCode == 125 { model?.moveCamVertically(amount: -1.0) }
            if event.keyCode == 123 { model?.moveCamHorizontally(amount: -1.0) }
            if event.keyCode == 124 { model?.moveCamHorizontally(amount: 1.0) }
            super.keyDown(with: event)
        }

        override func keyUp(with event: NSEvent) {
            if event.characters == "a" { model?.movementControl(x: 0.0, y: 0.0) }
            if event.characters == "d" { model?.movementControl(x: 0.0, y: 0.0) }
            if event.keyCode == 126 { model?.moveCamVertically(amount: 0.0) }
            if event.keyCode == 125 { model?.moveCamVertically(amount: 0.0) }
            if event.keyCode == 123 { model?.moveCamHorizontally(amount: 0.0) }
            if event.keyCode == 124 { model?.moveCamHorizontally(amount: 0.0) }
            super.keyUp(with: event)
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.model = model

        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
