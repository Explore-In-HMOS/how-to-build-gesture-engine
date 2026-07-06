import { KeyCode } from '@kit.InputKit'

// Input action identifiers
export enum Action {
  ZOOM = 'zoom',
  ROTATE = 'rotate',
  NEXT = 'next',
  PREV = 'prev',
  RESET = 'reset'
}

// Action categories
export enum ActionType {
  KEY = 'key',
  POINTER = 'pointer',
  TOUCH = 'touch',
  TILT = 'tilt'
}

// Input axes (accelerometer / gyroscope driven)
export enum Axis {
  X = 'x',
  Y = 'y',
  Z = 'z'
}

// Physical button -> hardware key mapping
export enum Button {
  TOP = KeyCode.KEYCODE_DPAD_RIGHT,
  BOTTOM = KeyCode.KEYCODE_DPAD_LEFT
}

// Axis reading with precision
export interface AxisValue {
  axis: Axis
  value: number
}

// Two-finger pinch-to-zoom: scale factor + center point
export interface Pinch {
  scale: number
  centerX: number
  centerY: number
}

// Two-finger rotation: angle delta
export interface Rotate {
  angleDelta: number
}
