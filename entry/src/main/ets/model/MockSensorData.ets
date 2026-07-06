// Mock accelerometer data — used to demo the tilt feature without a real device.
// Each frame is one accelerometer reading in m/s^2 (x, y, z), the same shape the
// real sensor.AccelerometerResponse delivers.
export interface SensorReading {
  x: number
  y: number
  z: number
}

// A full wrist-roll sweep: gravity (~9.8 m/s^2) rotates through the screen plane
// so the photo turns a smooth 360°. Played on a loop it looks like the device is
// being tilted around. Computed as x = 9.8*sin(theta), y = 9.8*cos(theta).
export const MOCK_FRAMES: SensorReading[] = [
  { x: 0.0, y: 9.8, z: 0.0 },     // 0°
  { x: 4.9, y: 8.49, z: 0.0 },    // 30°
  { x: 8.49, y: 4.9, z: 0.0 },    // 60°
  { x: 9.8, y: 0.0, z: 0.0 },     // 90°
  { x: 8.49, y: -4.9, z: 0.0 },   // 120°
  { x: 4.9, y: -8.49, z: 0.0 },   // 150°
  { x: 0.0, y: -9.8, z: 0.0 },    // 180°
  { x: -4.9, y: -8.49, z: 0.0 },  // 210°
  { x: -8.49, y: -4.9, z: 0.0 },  // 240°
  { x: -9.8, y: 0.0, z: 0.0 },    // 270°
  { x: -8.49, y: 4.9, z: 0.0 },   // 300°
  { x: -4.9, y: 8.49, z: 0.0 }    // 330°
]
