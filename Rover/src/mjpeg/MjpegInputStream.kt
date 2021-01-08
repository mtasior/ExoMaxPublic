import java.awt.image.BufferedImage
import java.io.*
import javax.imageio.ImageIO

/**
 * This is an [InputStream] with the ability to read MJPEG frames as [BufferedImage].
 *
 * @author Michael Tasior
 * Based on https://github.com/sarxos/webcam-capture/blob/master/webcam-capture/src/main/java/com/github/sarxos/webcam/util/MjpegInputStream.java by Bartosz Firyn (sarxos)
 */
class MjpegInputStream(inputStream: InputStream?) : DataInputStream(BufferedInputStream(inputStream, FRAME_MAX_LENGTH)) {
    private var open = true

    @Throws(IOException::class)
    private fun getEndOfSeqeunce(dataInputStream: DataInputStream, sequence: ByteArray): Int {
        var s = 0
        var c: Byte
        for (i in 0 until FRAME_MAX_LENGTH) {
            c = dataInputStream.readUnsignedByte().toByte()
            if (c == sequence[s]) {
                s++
                if (s == sequence.size) {
                    return i + 1
                }
            } else {
                s = 0
            }
        }
        return -1
    }

    @Throws(IOException::class)
    private fun getStartOfSequence(dataInputStream: DataInputStream, sequence: ByteArray): Int {
        val end = getEndOfSeqeunce(dataInputStream, sequence)
        return if (end < 0) -1 else end - sequence.size
    }

    @Throws(IOException::class, NumberFormatException::class)
    private fun parseContentLength(headerBytes: ByteArray): Int {
        ByteArrayInputStream(headerBytes).use { bais ->
            InputStreamReader(bais).use { isr ->
                BufferedReader(isr).use { br ->
                    var line: String?
                    while (br.readLine().also { line = it } != null) {
                        if (line!!.toLowerCase().startsWith(CONTENT_LENGTH)) {
                            val parts = line!!.split(":".toRegex()).toTypedArray()
                            if (parts.size == 2) {
                                return parts[1].trim { it <= ' ' }.toInt()
                            }
                        }
                    }
                }
            }
        }
        return 0
    }

    /**
     * Reads a single MJPEG frame (JPEG image) from stream and converts it into a [BufferedImage].
     *
     * @return JPEG image as [BufferedImage] or null
     * @throws IOException when there is a problem in reading from stream
     */
    @Throws(IOException::class)
    fun readFrame(): BufferedImage? {
        if (!open) {
            return null
        }
        mark(FRAME_MAX_LENGTH)
        val n = getStartOfSequence(this, SOI_MARKER)
        reset()
        val header = ByteArray(n)
        readFully(header)
        var length = try {
            parseContentLength(header)
        } catch (e: NumberFormatException) {
            getEndOfSeqeunce(this, EOI_MARKER)
        }
        if (length == 0) {
            println("Invalid MJPEG stream, EOI (0xFF,0xD9) not found!")
        }
        reset()
        val frame = ByteArray(length)
        skipBytes(n)
        readFully(frame)
        try {
            ByteArrayInputStream(frame).use { bais -> return ImageIO.read(bais) }
        } catch (e: IOException) {
            return null
        }
    }

    @Throws(IOException::class)
    override fun close() {
        try {
            super.close()
        } finally {
            open = false
        }
    }

    val isClosed: Boolean
        get() = !open

    companion object {

        /** Maximum header length. */
        private const val HEADER_MAX_LENGTH = 100

        /**Max frame length (100kB). */
        private const val FRAME_MAX_LENGTH = 100000 + HEADER_MAX_LENGTH

        /** The first two bytes of every JPEG frame are the Start Of Image (SOI) marker values FFh D8h. */
        private val SOI_MARKER = byteArrayOf(0xFF.toByte(), 0xD8.toByte())

        /** All JPEG data streams end with the End Of Image (EOI) marker values FFh D9h.*/
        private val EOI_MARKER = byteArrayOf(0xFF.toByte(), 0xD9.toByte())

        /** Name of content length header. */
        private val CONTENT_LENGTH = "Content-Length".toLowerCase()
    }
}