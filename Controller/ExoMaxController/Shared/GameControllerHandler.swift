//
//  GameControllerHandler.swift
//  ExoMaxController
//
//  Created by Michael Tasior on 25.12.20.
//

import Foundation
import GameController

class GameControllerHandler {
    private let model: ControllerModel

    init(model: ControllerModel) {
        self.model = model
        connectControllers()
        observeForGameControllers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func observeForGameControllers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connectControllers), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectControllers), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }

    @objc func connectControllers() {
        // Used to register the Controllers to a specific Player Number
        var indexNumber = 0
        // Run through each controller currently connected to the system
        for controller in GCController.controllers() {
            // Check to see whether it is an extended Game Controller (Such as a Nimbus)
            if controller.extendedGamepad != nil {
                controller.playerIndex = GCControllerPlayerIndex(rawValue: indexNumber)!
                indexNumber += 1
                setupControllerControls(controller: controller)
            }
        }
        // tell the model how many controllers are connected
        model.setConnectedControllers(number: indexNumber)
    }

    func setupControllerControls(controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = {
            (gamepad: GCExtendedGamepad, element: GCControllerElement) in
            // Add movement in here for sprites of the controllers
            self.controllerInputDetected(gamepad: gamepad, element: element, index: controller.playerIndex.rawValue)
        }
    }

    @objc func disconnectControllers() {
        // tell the model how many controllers are connected
        model.setConnectedControllers(number: model.numberConnectedControllers - 1)
    }

    func controllerInputDetected(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        // print("Controller \(element)")
        // Left Thumbstick
        if gamepad.leftThumbstick == element {
            model.movementControl(x: gamepad.leftThumbstick.xAxis.value, y: gamepad.leftThumbstick.yAxis.value)
        }
        // Right Thumbstick
        if gamepad.rightThumbstick == element {
            model.moveCamHorizontally(amount: Double(gamepad.rightThumbstick.xAxis.value))
            model.moveCamVertically(amount: Double(gamepad.rightThumbstick.yAxis.value))
        }
        // Y-Button
        else if gamepad.buttonY == element {
            if gamepad.buttonY.value == 0 {
                model.resetCamera()
            }
        }
        // A-Button
        else if gamepad.buttonA == element {
            if gamepad.buttonA.value == 0 {
                model.changeSteeringMode(to: SteeringMode.ACKERMANN)
            }
        }
        // X-Button
        else if gamepad.buttonX == element {
            if gamepad.buttonX.value == 0 {
                model.changeSteeringMode(to: SteeringMode.CRABBING)
            }
        }
        // B-Button
        else if gamepad.buttonB == element {
            if gamepad.buttonB.value == 0 {
                model.changeSteeringMode(to: SteeringMode.SPOT_TURN)
            }
        }
        // Left shoulder
        else if gamepad.leftShoulder == element {
            if gamepad.leftShoulder.value == 0 {
                model.increaseSpeed()
            }
        }
        // Right shoulder
        else if gamepad.rightShoulder == element {
            if gamepad.rightShoulder.value == 0 {
                model.decreaseSpeed()
            }
        }
        // Triggers
        else if gamepad.leftTrigger == element {
            if gamepad.leftTrigger.value == 0 {
                model.stop()
            }
        }
        // DPad
        else if gamepad.dpad == element {
            if gamepad.dpad.left.isPressed { model.camToLeftWheel() }
            if gamepad.dpad.right.isPressed { model.camToRightWheel() }
            if gamepad.dpad.up.isPressed { model.camToCenterHigh() }
            if gamepad.dpad.down.isPressed { model.camToCenterLow() }
        }
        else if gamepad.rightTrigger == element {
            if gamepad.rightTrigger.value == 0 {
                model.stop()
            }
        }
    }
}
