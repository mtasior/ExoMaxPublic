//
//  Protocol.swift
//  ExoMaxControllerTV
//
//  Created by Michael Tasior on 03.01.21.
//
// This file holds all objects that are exchanged using MQTT

import Foundation

/// All driving related values. All values shall be in [-100.0..100.0]
struct ControlState: Codable {
    let frd: Double // Front right drive
    let frs: Double // Front right steering
    let mrd: Double // Middle right drive
    let mrs: Double // Middle right steering
    let brd: Double // Back right drive
    let brs: Double // Back right steering
    let fld: Double
    let fls: Double
    let mld: Double
    let mls: Double
    let bld: Double
    let bls: Double
}

/// Camera position. All values shall be in [-100.0..100.0]
struct CameraPosition: Codable {
    let base: Double
    let top: Double
}

/// System State
struct SystemState: Codable {
    let linkQuality: Int  // X/60
    let signalLevel: Int  // in dBm
}
