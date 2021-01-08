import protocol.SystemState
import java.io.BufferedReader
import java.io.InputStreamReader
import kotlin.concurrent.thread


/**
 * This runs in a separate Thread and collects system information
 */
class SystemStateReader(mqttInterface: MqttInterface) {
    init {
        thread(true) {
            while (true) {
                val wifiState = getWifiState()
                mqttInterface.sendSystemState(SystemState(wifiState.linkQuality, wifiState.signalLevel))
                Thread.sleep(3000)
            }
        }
    }

    private fun getWifiState(): WifiState {
        val inputStream = Runtime.getRuntime().exec("iwconfig wlan0").inputStream
        val isReader = InputStreamReader(inputStream)
        val reader = BufferedReader(isReader)
        val sb = StringBuffer()
        var str: String?
        while (reader.readLine().also { str = it } != null) {
            sb.append(str)
        }
        val result = sb.toString()
        val link = result.split("Link Quality=")[1].split("/")[0].toInt()
        val level = result.split("Signal level=")[1].split(" ")[0].toInt()
        reader.close()
        return WifiState(link, level)
    }

    private data class WifiState(val linkQuality: Int, val signalLevel: Int)
}