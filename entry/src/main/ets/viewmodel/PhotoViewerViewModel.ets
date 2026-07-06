import { sensor } from '@kit.SensorServiceKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Action, ActionType, Axis, AxisValue, Button, Pinch, Rotate } from '../model/GestureModels'
import { MOCK_FRAMES, SensorReading } from '../model/MockSensorData'

@Observed
export class PhotoViewerViewModel {
  scaleValue: number = 1
  baseScale: number = 1
  angle: number = 0
  baseAngle: number = 0
  tiltAngle: number = 0
  tiltEnabled: boolean = false
  dragX: number = 0
  mockPlaying: boolean = false
  private mockTimer: number = -1
  private mockIndex: number = 0
  index: number = 0
  lastAction: string = ''
  pinchCenter: string = ''
  tilt: AxisValue[] = [
    { axis: Axis.X, value: 0 },
    { axis: Axis.Y, value: 0 },
    { axis: Axis.Z, value: 0 }
  ]

  readonly photos: Resource[] = [$r('app.media.p1'), $r('app.media.p2'), $r('app.media.p3')]

  // ---- lifecycle / sensor ----
  start(): void {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        this.applyReading(data.x, data.y, data.z)
      }, { interval: 100000000 })
    } catch (err) {
      const e = err as BusinessError
      this.lastAction = `sensor err ${e.code}: ${e.message}`
    }
  }

  stop(): void {
    this.clearMock()
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER)
    } catch (err) {
      const e = err as BusinessError
      this.lastAction = `off err ${e.code}`
    }
  }

  // Single entry point for any accelerometer reading — real sensor, mock, or manual.
  private applyReading(x: number, y: number, z: number): void {
    this.tilt = [
      { axis: Axis.X, value: Math.round(x * 1000) / 1000 },
      { axis: Axis.Y, value: Math.round(y * 1000) / 1000 },
      { axis: Axis.Z, value: Math.round(z * 1000) / 1000 }
    ]
    this.onTilt(x, y)
  }

  // ---- mock / manual sensor input ----
  // Auto-play the recorded frames so it looks like the device is being tilted.
  startMock(): void {
    if (this.mockPlaying) {
      return
    }
    this.stop()             // turn off real sensor so the two don't fight
    this.tiltEnabled = true // make the rotation visible while demoing
    this.mockPlaying = true
    this.mockIndex = 0
    this.mockTimer = setInterval(() => {
      const frame: SensorReading = MOCK_FRAMES[this.mockIndex]
      this.applyReading(frame.x, frame.y, frame.z)
      this.lastAction = `mock ${this.mockIndex + 1}/${MOCK_FRAMES.length}`
      this.mockIndex = (this.mockIndex + 1) % MOCK_FRAMES.length
    }, 200)
  }

  stopMock(): void {
    this.clearMock()
    this.start()            // hand control back to the real sensor
  }

  toggleMock(): void {
    if (this.mockPlaying) {
      this.stopMock()
    } else {
      this.startMock()
    }
  }

  // Feed one exact position (from the input fields or a preset button) and freeze it.
  setReading(x: number, y: number, z: number): void {
    this.stop()             // freeze: no real sensor, no mock playback overriding it
    this.tiltEnabled = true
    this.applyReading(x, y, z)
    this.lastAction = `set ${x}, ${y}, ${z}`
  }

  private clearMock(): void {
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer)
      this.mockTimer = -1
    }
    this.mockPlaying = false
  }

  axisValue(axis: Axis): number {
    const target: AxisValue | undefined = this.tilt.find((a: AxisValue) => a.axis === axis)
    return target ? target.value : 0
  }

  // Tilt-to-rotate: turn the gravity vector in the screen plane into an angle.
  // Flat (face up) -> x,y near 0, so a deadzone keeps the photo still and avoids jitter.
  onTilt(x: number, y: number): void {
    if (!this.tiltEnabled) {
      return
    }
    const magnitude: number = Math.sqrt(x * x + y * y)
    const deadzone: number = 1.5 // m/s^2; below this the watch is roughly flat
    const next: number = magnitude < deadzone
      ? 0
      : Math.round(Math.atan2(x, y) * 180 / Math.PI)
    if (next === this.tiltAngle) {
      return
    }
    this.tiltAngle = next
    this.angle = this.baseAngle + this.tiltAngle
    this.dispatch(Action.ROTATE, ActionType.TILT)
  }

  // Toggle whether the accelerometer rotates the photo.
  toggleTilt(): void {
    this.tiltEnabled = !this.tiltEnabled
    if (!this.tiltEnabled) {
      this.tiltAngle = 0
      this.angle = this.baseAngle
    }
  }

  // ---- gesture handlers ----
  onPinch(p: Pinch): void {
    this.scaleValue = Math.max(0.5, Math.min(this.baseScale * p.scale, 5))
    this.pinchCenter = `${p.centerX.toFixed(0)}, ${p.centerY.toFixed(0)}`
    this.dispatch(Action.ZOOM, ActionType.TOUCH)
  }

  commitPinch(): void {
    this.baseScale = this.scaleValue
  }

  onRotate(r: Rotate): void {
    this.angle = this.baseAngle + this.tiltAngle + r.angleDelta
    this.dispatch(Action.ROTATE, ActionType.TOUCH)
  }

  commitRotate(): void {
    // Keep only the gesture part in baseAngle so live tilt isn't baked in.
    this.baseAngle = this.angle - this.tiltAngle
  }

  // ---- on-screen button actions ----
  zoomIn(): void {
    this.scaleValue = Math.min(this.scaleValue + 0.25, 5)
    this.baseScale = this.scaleValue
    this.dispatch(Action.ZOOM, ActionType.POINTER)
  }

  zoomOut(): void {
    this.scaleValue = Math.max(this.scaleValue - 0.25, 0.5)
    this.baseScale = this.scaleValue
    this.dispatch(Action.ZOOM, ActionType.POINTER)
  }

  rotateStep(): void {
    this.baseAngle = this.baseAngle + 90
    this.angle = this.baseAngle + this.tiltAngle
    this.dispatch(Action.ROTATE, ActionType.POINTER)
  }

  onButton(btn: Button): void {
    if (btn === Button.TOP) {
      this.next()
      this.dispatch(Action.NEXT, ActionType.KEY)
    }
    if (btn === Button.BOTTOM) {
      this.prev()
      this.dispatch(Action.PREV, ActionType.KEY)
    }
  }

  swipeNext(): void {
    this.next()
    this.dispatch(Action.NEXT, ActionType.POINTER)
  }

  swipePrev(): void {
    this.prev()
    this.dispatch(Action.PREV, ActionType.POINTER)
  }

  // ---- internal ----
  dispatch(action: Action, type: ActionType): void {
    this.lastAction = `${type}:${action}`
  }

  reset(): void {
    this.scaleValue = 1
    this.baseScale = 1
    this.baseAngle = 0
    // Keep current tilt so the photo stays consistent with how the watch is held.
    this.angle = this.tiltAngle
    this.dispatch(Action.RESET, ActionType.TOUCH)
  }

  next(): void {
    this.index = (this.index + 1) % this.photos.length
    this.reset()
  }

  prev(): void {
    this.index = (this.index - 1 + this.photos.length) % this.photos.length
    this.reset()
  }

  currentPhoto(): Resource {
    return this.photos[this.index]
  }
}
