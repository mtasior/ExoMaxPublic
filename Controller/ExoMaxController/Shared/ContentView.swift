//
//  ContentView.swift
//  Shared
//
//  Created by Michael Tasior on 25.12.20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: ControllerModel

    let cornerRadius = CGFloat(10.0)
    #if os(tvOS)
    let buttonSize = CGFloat(120.0)
    let fontSize = CGFloat(60.0)
    let padding = CGFloat(10.0)
    #else
    let buttonSize = CGFloat(60.0)
    let fontSize = CGFloat(40.0)
    let padding = CGFloat(0.0)
    #endif

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: cornerRadius) {
                Button(action: { model.changeSteeringMode(to: SteeringMode.ACKERMANN) }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill").font(.system(size: fontSize)).frame(width: buttonSize, height: buttonSize, alignment: .center)
                }.buttonStyle(DrivingModeButtonStyle(isActive: model.steeringMode == SteeringMode.ACKERMANN, radius: cornerRadius))
                Button(action: { model.changeSteeringMode(to: SteeringMode.CRABBING) }) {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward.circle.fill")
                        .font(.system(size: fontSize)).frame(width: buttonSize, height: buttonSize, alignment: .center)
                }.buttonStyle(DrivingModeButtonStyle(isActive: model.steeringMode == SteeringMode.CRABBING, radius: cornerRadius))
                Button(action: { model.changeSteeringMode(to: SteeringMode.SPOT_TURN) }) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: fontSize)).frame(width: buttonSize, height: buttonSize, alignment: .center)
                }.buttonStyle(DrivingModeButtonStyle(isActive: model.steeringMode == SteeringMode.SPOT_TURN, radius: cornerRadius))
                Button(action: { model.stop() }) {
                    Image(systemName: "lock.circle.fill").font(.system(size: fontSize)).frame(width: buttonSize, height: buttonSize, alignment: .center)
                }.buttonStyle(DrivingModeButtonStyle(isActive: model.constantSpeed, radius: cornerRadius))

                Button(action: {}) {
                    VStack {
                        Text("\(model.systemState.linkQuality) / 70")
                            .font(.footnote)
                        Text("\(model.systemState.signalLevel) dBm")
                            .font(.footnote)
                    }.frame(width: buttonSize)
                }.buttonStyle(DrivingModeButtonStyle(isActive: false, radius: cornerRadius))

                Spacer()

                // This is the simplest but not the most elegant way
                HStack(alignment: .center) {
                    if model.numberConnectedControllers > 0 {
                        Image(systemName: "gamecontroller.fill").foregroundColor(Color("AccentColor"))
                    }
                    if model.numberConnectedControllers > 1 {
                        Image(systemName: "gamecontroller.fill").foregroundColor(Color("AccentColor"))
                    }
                }
                HStack(alignment: .center) {
                    if model.numberConnectedControllers > 2 {
                        Image(systemName: "gamecontroller.fill").foregroundColor(Color("AccentColor"))
                    }
                    if model.numberConnectedControllers > 3 {
                        Image(systemName: "gamecontroller.fill").foregroundColor(Color("AccentColor"))
                    }
                }
            }.padding(padding)
            Spacer()
            VStack {
                model.image
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(cornerRadius)
                    .aspectRatio(contentMode: .fit)
                Spacer(minLength: 0)
            }
            Spacer()
        }
    }
}

struct DrivingModeButtonStyle: ButtonStyle {
    var isActive: Bool
    var radius: CGFloat

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .background(isActive ? Color("AccentColor") : Color.gray)
            .cornerRadius(radius)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ControllerModel())
    }
}
