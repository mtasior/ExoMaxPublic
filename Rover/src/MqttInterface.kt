import MqttInterface.ControlUpdateReceiver
import com.google.gson.Gson
import org.eclipse.paho.client.mqttv3.MqttClient
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttMessage
import protocol.CameraPosition
import protocol.ControlState
import protocol.SystemState
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO


/**
 * The interface to our MQTT Server which handles all communication.
 * It decodes commands and propagates them to a provided [ControlUpdateReceiver]
 */
class MqttInterface {
    private val gson = Gson()

    private val options = MqttConnectOptions()

    private val mqttClient = MqttClient("tcp://exomax:1883", "ExoMaxRover")

    /** Used for encoding BufferedImages to Byte Arrays */
    val baos = ByteArrayOutputStream()

    private var controlUpdateReceiver: ControlUpdateReceiver? = null

    /**
     * Connect to the given MQTT Server
     *
     * @return This [MqttInterface]. Can be used to chain calls.
     */
    fun connect(): MqttInterface {
        mqttClient.connect(options)
        mqttClient.subscribe(TOPIC_CONTROL) { _, p1 -> p1?.let { receiveControlUpdate(it) } }
        mqttClient.subscribe(TOPIC_CAMERA) { _, p1 -> p1?.let { receiveCameraUpdate(it) } }
        return this
    }

    /**
     * Set a command receiver.
     */
    fun setControlUpdateReceiver(receiver: ControlUpdateReceiver?) {
        controlUpdateReceiver = receiver
    }

    /**
     * Sends a [BufferedImage] to the appropriate topic.
     * QOS is set to 0 as we are using it to transport a video stream, dropping frames is OK. For more information see
     * https://www.hivemq.com/blog/mqtt-essentials-part-6-mqtt-quality-of-service-levels/
     */
    fun sendImage(img: BufferedImage) {
        ImageIO.write(img, "jpg", baos)
        val bytes = baos.toByteArray()
        baos.reset()
        mqttClient.publish(TOPIC_VIDEO, bytes, 0, false)
    }

    /**
     * Send the system State
     */
    fun sendSystemState(state: SystemState) {
        mqttClient.publish(TOPIC_SYSTEM_STATE, gson.toJson(state).toByteArray(charset(CHARSET)), 0, false)
    }

    private fun receiveControlUpdate(mqttMessage: MqttMessage) {
        try {
            val msg = String(mqttMessage.payload, charset(CHARSET))
            val message = gson.fromJson(msg, ControlState::class.java)
            controlUpdateReceiver?.onControlUpdateReceived(message)
        } catch (e: Exception) {
            println(e)
        }
    }

    private fun receiveCameraUpdate(mqttMessage: MqttMessage) {
        try {
            val msg = String(mqttMessage.payload, charset(CHARSET))
            val message = gson.fromJson(msg, CameraPosition::class.java)
            controlUpdateReceiver?.onCameraPositionReceived(message)
        } catch (e: Exception) {
            println(e)
        }
    }

    companion object {
        const val CHARSET = "UTF-8"
        const val TOPIC_CONTROL = "exomax/control"
        const val TOPIC_CAMERA = "exomax/camera"
        const val TOPIC_VIDEO = "exomax/video"
        const val TOPIC_SYSTEM_STATE = "exomax/systemstate"
    }

    /**
     * The interface for all control command receivers
     */
    interface ControlUpdateReceiver {
        fun onControlUpdateReceived(update: ControlState)
        fun onCameraPositionReceived(update: CameraPosition)
    }
}