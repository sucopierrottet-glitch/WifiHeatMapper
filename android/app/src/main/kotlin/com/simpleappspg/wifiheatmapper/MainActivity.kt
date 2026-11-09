package com.simpleappspg.wifiheatmapper

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.atan2
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), SensorEventListener {
    private val CHANNEL = "com.simpleappspg.sensors/data"
    private var sensorManager: SensorManager? = null

    private var accel = FloatArray(3) { 0f }
    private var gyro = FloatArray(3) { 0f }
    private var mag = FloatArray(3) { 0f }
    private var pressure: Float = 1013.25f
    private var lightLux: Float = 450f
    private var hasBarometer = false
    private var hasLight = false
    private var hasMag = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        registerSensors()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSensorSnapshot") {
                val ax = accel[0].toDouble()
                val ay = accel[1].toDouble()
                val az = accel[2].toDouble()
                val pitch = Math.toDegrees(atan2(ay, sqrt(ax * ax + az * az)))
                val roll = Math.toDegrees(atan2(-ax, az))

                var azimuth = 0.0
                val rMat = FloatArray(9)
                val iMat = FloatArray(9)
                if (SensorManager.getRotationMatrix(rMat, iMat, accel, mag)) {
                    val orientation = FloatArray(3)
                    SensorManager.getOrientation(rMat, orientation)
                    azimuth = (Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0
                }

                val magStrength = sqrt(
                    (mag[0] * mag[0] + mag[1] * mag[1] + mag[2] * mag[2]).toDouble()
                )

                val data = mapOf(
                    "ax" to ax,
                    "ay" to ay,
                    "az" to az,
                    "gx" to gyro[0].toDouble(),
                    "gy" to gyro[1].toDouble(),
                    "gz" to gyro[2].toDouble(),
                    "mx" to mag[0].toDouble(),
                    "my" to mag[1].toDouble(),
                    "mz" to mag[2].toDouble(),
                    "magFieldUt" to if (magStrength > 0.1) magStrength else 46.5,
                    "pressureHpa" to pressure.toDouble(),
                    "lightLux" to lightLux.toDouble(),
                    "pitch" to pitch,
                    "roll" to roll,
                    "azimuth" to azimuth,
                    "hasBarometer" to hasBarometer,
                    "hasLight" to hasLight,
                    "hasMag" to hasMag
                )
                result.success(data)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun registerSensors() {
        val sm = sensorManager ?: return
        sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)?.let {
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)?.let {
            hasMag = true
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        sm.getDefaultSensor(Sensor.TYPE_PRESSURE)?.let {
            hasBarometer = true
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        sm.getDefaultSensor(Sensor.TYPE_LIGHT)?.let {
            hasLight = true
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val e = event ?: return
        when (e.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> accel = e.values.clone()
            Sensor.TYPE_GYROSCOPE -> gyro = e.values.clone()
            Sensor.TYPE_MAGNETIC_FIELD -> mag = e.values.clone()
            Sensor.TYPE_PRESSURE -> if (e.values.isNotEmpty()) pressure = e.values[0]
            Sensor.TYPE_LIGHT -> if (e.values.isNotEmpty()) lightLux = e.values[0]
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
