package protocol

data class ControlState(
    val frd: Double,
    val frs: Double,
    val mrd: Double,
    val mrs: Double,
    val brd: Double,
    val brs: Double,
    val fld: Double,
    val fls: Double,
    val mld: Double,
    val mls: Double,
    val bld: Double,
    val bls: Double
)

data class CameraPosition(
    val base: Double,
    val top: Double
)

data class SystemState(
    val linkQuality: Int, // Raspbian delivers link quality e.g. 35/70
    val signalLevel: Int // In dBm
)