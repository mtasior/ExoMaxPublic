import java.awt.image.BufferedImage
import kotlin.concurrent.thread


/**
 * The [VideoStreamController] reads an MJPEG stream from a local motion instance that streams the video of the connected Raspi Cam.
 * Every frame is read, transformed and published via mqtt.
 * It can receive control commands that change the size and frequency of the resulting jpeg stream.
 * This way the video quality can be controlled by the client during runtime.
 *
 *
 */
class VideoStreamController(private val mqtt: MqttInterface) : MjpegFrameReader.FrameListener {
    private val frameReader = MjpegFrameReader("http://localhost:8081")

    init {
        with(frameReader) {
            frameListener = this@VideoStreamController
            thread(true) { loop() }
        }
    }

    override fun onFrame(frame: BufferedImage) {
        val resized = frame.resize(640, 480)
        mqtt.sendImage(resized)
    }
}

/**
 * We want to resize images from the motion stream to a smaller version
 */
fun BufferedImage.resize(x: Int, y: Int): BufferedImage {
    val resizedImage = BufferedImage(width, height, this.type)
    val g = resizedImage.createGraphics()
    g.drawImage(this, 0, 0, width, height, null)
    g.dispose()
    return resizedImage
}