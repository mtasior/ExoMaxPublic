import com.pi4j.gpio.extension.pca.PCA9685GpioProvider
import com.pi4j.gpio.extension.pca.PCA9685Pin
import com.pi4j.io.gpio.GpioFactory
import com.pi4j.io.gpio.GpioPinPwmOutput
import com.pi4j.io.i2c.I2CBus
import com.pi4j.io.i2c.I2CFactory
import protocol.CameraPosition
import protocol.ControlState
import java.math.BigDecimal
import kotlin.math.roundToInt

/**
 * The Servos are all connected to a PWM HAT using the PCA9685 Chip.
 * This class provides a simple interface to control the rover, the camera and to calibrate all servos.
 */
class ServoController {
    val provider: PCA9685GpioProvider
    private val gpio = GpioFactory.getInstance()

    init {
        val frequency = BigDecimal("48.828")
        val frequencyCorrectionFactor = BigDecimal("1.0578")
        val bus = I2CFactory.getInstance(I2CBus.BUS_1)
        provider = PCA9685GpioProvider(bus, 0x40, frequency, frequencyCorrectionFactor)

        Runtime.getRuntime().addShutdownHook(Thread { provider.shutdown() })
    }

    /**
     * These must be updated according to the specific Rover configuration.
     */
    private val frd = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_03, "frd"))
    private val frs = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_00, "frs"), offset = -1.0, minDuration = 550, maxDuration = 2450)
    private val mrd = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_02, "mrd"), offset = 0.5)
    private val mrs = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_01, "mrs"), offset = -3.0, minDuration = 550, maxDuration = 2450)
    private val brd = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_06, "brd"), offset = 2.0)
    private val brs = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_05, "brs"), offset = 1.0, minDuration = 550, maxDuration = 2450)
    private val fld = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_08, "fld"), sign = -1.0, offset = 2.0)
    private val fls = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_11, "fls"), offset = 1.0, minDuration = 550, maxDuration = 2450)
    private val mld = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_09, "mld"), sign = -1.0)
    private val mls = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_10, "mls"), offset = -4.0, minDuration = 550, maxDuration = 2450)
    private val bld = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_07, "bld"), sign = -1.0, offset = 2.0)
    private val bls = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_04, "bls"), offset = -5.0, minDuration = 550, maxDuration = 2450)

    private val camBase =
        Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_12, "camBase"), offset = -12.0, minDuration = 550, maxDuration = 2450)
    private val camTop = Servo(gpio.provisionPwmOutputPin(provider, PCA9685Pin.PWM_13, "camTop"), minDuration = 1150, maxDuration = 2450)

    private val stopAllControlState = ControlState(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    /**
     * Set a new camera position
     */
    fun applyCameraPosition(pos: CameraPosition) {
        setServo(camBase, pos.base)
        setServo(camTop, pos.top)
    }

    /**
     * Apply a new control state to the drive
     */
    fun applyControlState(state: ControlState) {
        setServo(frd, state.frd)
        setServo(frs, state.frs)
        setServo(mrd, state.mrd)
        setServo(mrs, state.mrs)
        setServo(brd, state.brd)
        setServo(brs, state.brs)
        setServo(fld, state.fld)
        setServo(fls, state.fls)
        setServo(mld, state.mld)
        setServo(mls, state.mls)
        setServo(bld, state.bld)
        setServo(bls, state.bls)

        /** If we want to stop everything, we also want to switch off all servos */
        if (state == stopAllControlState) {
            println("Shutting down the provider")
            provider.shutdown()
        }
    }

    /**
     * Sets the pwm between -100 and 100
     */
    private fun setServo(servo: Servo, newValue: Double) {
        val desired = newValue.coerceIn(-100.0, 100.0) * servo.sign + servo.offset + 100.0
        val duration = servo.minDuration + ((servo.maxDuration - servo.minDuration).toDouble() * desired / 200.0)
        provider.setPwm(servo.pwmOutput.pin, duration.roundToInt())
    }

    private data class Servo(
        val pwmOutput: GpioPinPwmOutput,
        val sign: Double = 1.0,
        val offset: Double = 0.0,
        val minDuration: Int = 1410,
        val maxDuration: Int = 1610
    )
}