//
//  ControlStateGenerator.swift
//  ExoMaxController
//
//  Created by Michael Tasior on 18.01.21.
//

import Foundation

class ControlStateGenerator {
    /// Geometry of ExoMax, distances between turning points
    let width = 20.0
    let length = 30.0

    func spot(x: Double, y: Double) -> ControlState {
        return ControlState(frd: -x, frs: -50.0, mrd: -0.8 * x, mrs: 0.0, brd: -x, brs: 50.0, fld: x, fls: 50.0, mld: 0.8 * x, mls: 0.0, bld: x, bls: -50.0)
    }

    func crab(x: Double, y: Double) -> ControlState {
        return ControlState(frd: y, frs: x, mrd: y, mrs: x, brd: y, brs: x, fld: y, fls: x, mld: y, mls: x, bld: y, bls: x)
    }

    /// Generates a ControlState using Ackermann geometry
    /// - Parameters:
    ///   - x: from -100 to 100
    ///   - y: from -100 to 100
    /// - Returns: ControlState
    func ackermann(x: Double, y: Double) -> ControlState {
        // squared and dampened raw input
        let percent = x / 100.0
        let desiredAngle = controlValueToAngleDegrees(raw: percent * percent * percent * 5.0)

        let flsRaw = angleAtWheel(horizontalDisplacement: -width / 2, longitudinalDisplacement: length / 2, desiredAngleDegrees: desiredAngle)
        let frsRaw = angleAtWheel(horizontalDisplacement: width / 2, longitudinalDisplacement: length / 2, desiredAngleDegrees: desiredAngle)

        // maths is only correct for right turns, for left turns we must rotate
        var fls = flsRaw
        var frs = frsRaw
        if x < 0 {
            fls = frsRaw
            frs = flsRaw
        }

        // imaginary circle circumference the inner and outer wheels drive on. outer wheels must turn faster than inner
        let leftCircle = 2 * sin(deg2rad(fls)) * .pi * y
        let rightCircle = 2 * sin(deg2rad(frs)) * .pi * y

        var circleRatio = 1.0
        if rightCircle != 0.0 { circleRatio = leftCircle / rightCircle } //

        var leftRatio = circleRatio
        var rightRatio = circleRatio
        if circleRatio < leftRatio { rightRatio = 1 / circleRatio } else { leftRatio = 1.0 / circleRatio }

        return ControlState(frd: rightRatio * y, frs: frs,
                            mrd: rightRatio * y, mrs: 0.0,
                            brd: rightRatio * y, brs: -frs,
                            fld: leftRatio * y, fls: fls,
                            mld: leftRatio * y, mls: 0.0,
                            bld: leftRatio * y, bls: -fls)
    }

    /// We map a control value in [-100..100] to [-90.. 90 degrees]
    private func controlValueToAngleDegrees(raw: Double) -> Double {
        return raw / 100.0 * 90.0
    }

    private func angleDegreesToControlValue(angle: Double) -> Double {
        return 100.0 * angle / 90.0
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180.0
    }

    func rad2deg(_ number: Double) -> Double {
        return number * 180.0 / .pi
    }

    /// This calculates the desired angle at a wheel with the given displacements. Only correct for left turns (negative values)
    /// - Parameters:
    ///   - horizontalDisplacement: horizontal displacement. Negative when left wheel, positive when right wheel. Distance from rover center to steering axis
    ///   - longitudinalDisplacement: longitudinal displacement. positive to the front, negative to the back. Distance from rover center to steering axis
    ///   - desiredAngleDegrees: desired angle of a tangential to circle which is concentric with all wheel circles and goes through the center of the rover. Negative to the left. In degrees
    /// - Returns: an angle the given wheel has to be oriented. negative to the left.
    private func angleAtWheel(horizontalDisplacement hd: Double, longitudinalDisplacement ld: Double, desiredAngleDegrees da: Double) -> Double {
        var sign = 1.0
        if da < 0.0 { sign = -1.0 }
        let y = hd - sqrt(ld) * sqrt(1.0 / sin(deg2rad(abs(da))))
        let result = rad2deg(asin(ld / sqrt(ld * ld + y * y)))
        return sign * result
    }
}
