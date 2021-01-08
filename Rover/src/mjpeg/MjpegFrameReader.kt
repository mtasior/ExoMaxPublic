import java.awt.image.BufferedImage
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread


class MjpegFrameReader(val streamUrl: String) {
    var frameListener: FrameListener? = null

    fun loop() {
        val url = URL(streamUrl)
        val urlConnection = url.openConnection() as HttpURLConnection
        val stream = MjpegInputStream(urlConnection.inputStream)

        Runtime.getRuntime().addShutdownHook(
            thread(start = false) { stream.close() }
        )

        while (true) {
            stream.readFrame()?.let {
                frameListener?.onFrame(it)
            }
        }
    }

    interface FrameListener {
        fun onFrame(frame: BufferedImage): Unit
    }
}