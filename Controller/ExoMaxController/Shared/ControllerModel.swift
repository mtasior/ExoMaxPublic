//
//  Model.swift
//  ExoMaxController
//
//  Created by Michael Tasior on 25.12.20.
//

import Combine
import GameController
import SwiftMQTT
import SwiftUI

class ControllerModel: ObservableObject, MQTTSessionDelegate {
    @Published var steeringMode = SteeringMode.ACKERMANN
    @Published var x = 0.0
    @Published var y = 0.0
    @Published var constantSpeed = false
    @Published var camX = 0.0
    @Published var camY = 40.0
    @Published var image = Image(systemName: "video.circle")
    @Published var numberConnectedControllers = 0
    @Published var systemState = SystemState(linkQuality: 0, signalLevel: 0)

    private var camMovesX = 0.0
    private var camMovesY = 0.0

    private let mqttSession = MQTTSession(host: "exomax", port: 1883, clientID: "ExoMaxController\(UUID().uuidString)", cleanSession: true, keepAlive: 5, useSSL: false)

    private var gameControllerHandler: GameControllerHandler?
    private let jsonEncoder = JSONEncoder()
    private let controlStateGenerator = ControlStateGenerator()

    private var controlCancellable: AnyCancellable?
    private var cameraCancellable: AnyCancellable?
    private var camMoveCancellable: AnyCancellable?

    private let TOPIC_VIDEO = "exomax/video"
    private let TOPIC_SYSTEM_STATE = "exomax/systemstate"

    /// Setup the model. This connects to the MQTT session and sets up all cancellable.
    func setup() {
        gameControllerHandler = GameControllerHandler(model: self)

        mqttSession.delegate = self

        mqttSession.connect { error in
            if error == .none {
                print("Connected!")
                self.mqttSession.subscribe(to: self.TOPIC_VIDEO, delivering: .atLeastOnce) { error in
                    if error == .none {
                        print("Subscribed to \(self.TOPIC_VIDEO)")
                    } else {
                        print(error.description)
                    }
                }
                self.mqttSession.subscribe(to: self.TOPIC_SYSTEM_STATE, delivering: .atLeastOnce) { error in
                    if error == .none {
                        print("Subscribed to \(self.TOPIC_SYSTEM_STATE)")
                    } else {
                        print(error.description)
                    }
                }
            } else { print(error.description) }
        }

        controlCancellable = $x
            .combineLatest($y, $steeringMode) { x, y, steeringMode in
                self.generateControlState(x: x, y: y, steeringMode: steeringMode)
            }
            // we do not want to swamp the mqtt in messages
            .throttle(for: .milliseconds(80), scheduler: RunLoop.main, latest: true)
            .sink { controlState in
                self.sendControlState(controlState: controlState)
            }

        cameraCancellable = $camX
            .combineLatest($camY) { x, y in
                CameraPosition(base: x, top: y)
            }
            .removeDuplicates { a, b in a.base == b.base && a.top == b.top }
            .throttle(for: .milliseconds(80), scheduler: RunLoop.main, latest: true)
            .sink { cameraPosition in
                self.sendCameraPosition(controlState: cameraPosition)
            }

        camMoveCancellable = Timer.publish(every: 0.05, on: RunLoop.main, in: RunLoop.Mode.default)
            .autoconnect()
            .filter { _ in self.camMovesX != 0.0 || self.camMovesY != 0.0 }
            .sink { _ in
                self.camX = (self.camX - self.camMovesX).clamped(to: -100 ... 100)
                self.camY = (self.camY - self.camMovesY).clamped(to: -100 ... 100)
            }
    }

    /// Teardown the model. Should be called as soon as the app is not in foreground mode.
    func teardown() {
        mqttSession.disconnect()
        controlCancellable?.cancel()
        cameraCancellable?.cancel()
        camMoveCancellable?.cancel()
    }

    /// Movement control for the rover.
    /// - Parameters:
    ///   - x: horizontal movement in [-100..100] (steering)
    ///   - y: longitudinal movement in [-100..100] (speed)
    func movementControl(x: Float, y: Float) {
        self.x = Double(x * 100.0)
        if !constantSpeed { self.y = Double(y * 100.0) }
    }

    /// Set a new steering mode
    /// - Parameter newmode: The desired new steering mode
    func changeSteeringMode(to newmode: SteeringMode) {
        steeringMode = newmode
    }

    /// In order to show the number of connected controllers, the GameControllerHandler must set them here.
    /// - Parameter number: Number of connected Gamecontrollers.
    func setConnectedControllers(number: Int) {
        numberConnectedControllers = number
    }

    /// Increase speed by 10 and lock speed control to this value.
    func increaseSpeed() {
        constantSpeed = true
        y += 10.0
        y = y.clamped(to: -100.0 ... 100.0)
    }

    /// Decrease speed by 10 and lock speed control to this value
    func decreaseSpeed() {
        constantSpeed = true
        y -= 10.0
        y = y.clamped(to: -100.0 ... 100.0)
    }

    /// Move camera horizontally by the given amount
    func moveCamHorizontally(amount: Double) {
        camMovesX = 3 * amount * abs(amount)
    }

    /// Move camera vertically by the given amount
    func moveCamVertically(amount: Double) {
        camMovesY = 2 * amount * abs(amount)
    }

    /// Center the camera
    func resetCamera() {
        camMovesY = 0.0
        camMovesX = 0.0
        camX = 0.0
        camY = 40.0
    }

    func camToRightWheel() {
        camMovesY = 0.0
        camMovesX = 0.0
        camX = -45.0
        camY = 100
    }

    func camToLeftWheel() {
        camMovesY = 0.0
        camMovesX = 0.0
        camX = 45.0
        camY = 100
    }

    func camToCenterLow() {
        camMovesY = 0.0
        camMovesX = 0.0
        camX = 0.0
        camY = 100
    }

    func camToCenterHigh() {
        camMovesY = 0.0
        camMovesX = 0.0
        camX = 0.0
        camY = -22
    }

    /// Set speed to 0 and reset stick speed control
    func stop() {
        constantSpeed = false
        y = 0.0
        y = y.clamped(to: -100.0 ... 100.0)
    }

    // MARK: MQTT Stuff

    func mqttDidAcknowledgePing(from session: MQTTSession) {
        // do nothing
    }

    func mqttDidDisconnect(session: MQTTSession, error: MQTTSessionError) {
        // do nothing for now
    }

    func mqttDidReceive(message: MQTTMessage, from session: MQTTSession) {
        if message.topic == TOPIC_VIDEO {
            #if os(macOS)
            if let newImage = NSImage(data: message.payload) {
                image = Image(nsImage: newImage)
            }
            #else
            if let newImage = UIImage(data: message.payload) {
                image = Image(uiImage: newImage)
            }
            #endif
        }

        if message.topic == TOPIC_SYSTEM_STATE {
            if let decoded = try? JSONDecoder().decode(SystemState.self, from: message.payload) {
                systemState = decoded
            }
        }
    }

    // MARK: Control Functions

    /// Generates a ControlState based on the current driving mode
    ///
    // TODO: Make Ackermann better.
    ///
    /// - Parameters:
    ///   - x: from -100 to 100
    ///   - y: from -100 to 100
    private func generateControlState(x: Double, y: Double, steeringMode: SteeringMode) -> ControlState {
        switch steeringMode {
        case .SPOT_TURN:
            return controlStateGenerator.spot(x: x, y: y)
        case .CRABBING:
            return controlStateGenerator.crab(x: x, y: y)
        case .ACKERMANN:
            return controlStateGenerator.ackermann(x: x, y: y)
        }
    }

    // MARK: Send to Rover using MQTT

    private func sendControlState(controlState: ControlState) {
        let data = try! jsonEncoder.encode(controlState)
        let topic = "exomax/control"

        mqttSession.publish(data, in: topic, delivering: .atLeastOnce, retain: false) { error in
            if error == .none {
                print("Published data in \(topic)!")
            } else {
                print(error.description)
            }
        }
    }

    private func sendCameraPosition(controlState: CameraPosition) {
        let data = try! jsonEncoder.encode(controlState)
        let topic = "exomax/camera"

        mqttSession.publish(data, in: topic, delivering: .atLeastOnce, retain: false) { error in
            if error == .none {
                print("Published data in \(topic)!")
            } else {
                print(error.description)
            }
        }
    }
}

enum SteeringMode: String {
    case SPOT_TURN, CRABBING, ACKERMANN

    func next() -> SteeringMode {
        switch self {
        case .SPOT_TURN: return .CRABBING
        case .CRABBING: return .ACKERMANN
        case .ACKERMANN: return .SPOT_TURN
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
