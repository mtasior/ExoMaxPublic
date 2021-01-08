import protocol.CameraPosition
import protocol.ControlState

object RoverMain {
    @JvmStatic
    fun main(args: Array<String>) {
        val servoController = ServoController()
        val mqtt = MqttInterface().connect()
        VideoStreamController(mqtt)
        SystemStateReader(mqtt)
        mqtt.setControlUpdateReceiver(object : MqttInterface.ControlUpdateReceiver {
            override fun onControlUpdateReceived(update: ControlState) {
                servoController.applyControlState(update)
            }

            override fun onCameraPositionReceived(update: CameraPosition) {
                servoController.applyCameraPosition(update)
            }
        })
    }
}