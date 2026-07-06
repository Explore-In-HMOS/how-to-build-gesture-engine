import { Axis, Button } from '../model/GestureModels'
import { PhotoViewerViewModel } from '../viewmodel/PhotoViewerViewModel'

@Entry
@Component
struct Index {
  @State vm: PhotoViewerViewModel = new PhotoViewerViewModel()
  @State mx: string = '0'
  @State my: string = '9.8'
  @State mz: string = '0'

  aboutToAppear(): void {
    this.vm.start()
  }

  aboutToDisappear(): void {
    this.vm.stop()
  }

  @Builder
  ctrlButton(label: string, action: () => void) {
    Text(label)
      .fontSize(16)
      .fontColor(Color.White)
      .width(34)
      .height(34)
      .textAlign(TextAlign.Center)
      .borderRadius(17)
      .backgroundColor('#66FFFFFF')
      .onClick(action)
  }

  build() {
    Stack() {
      Image(this.vm.currentPhoto())
        .objectFit(ImageFit.Contain)
        .width('100%')
        .height('100%')
        .scale({ x: this.vm.scaleValue, y: this.vm.scaleValue })
        .rotate({ angle: this.vm.angle })
        .translate({ x: this.vm.dragX })

      Column() {
        Text(`${this.vm.index + 1} / ${this.vm.photos.length}`)
          .fontSize(14)
          .fontColor(Color.White)
        Text(this.vm.lastAction)
          .fontSize(11)
          .fontColor('#CCFFFFFF')
        Text(`X ${this.vm.axisValue(Axis.X)}  Y ${this.vm.axisValue(Axis.Y)}  Z ${this.vm.axisValue(Axis.Z)}`)
          .fontSize(10)
          .fontColor('#CCFFFFFF')
        Text(this.vm.tiltEnabled ? 'tilt: ON' : 'tilt: OFF')
          .fontSize(10)
          .fontColor(this.vm.tiltEnabled ? '#FF7CFC00' : '#FFAAAAAA')
          .onClick(() => {
            this.vm.toggleTilt()
          })

        Row({ space: 6 }) {
          this.ctrlButton('‹', () => { this.vm.swipePrev() })
          this.ctrlButton('−', () => { this.vm.zoomOut() })
          this.ctrlButton('⟳', () => { this.vm.rotateStep() })
          this.ctrlButton('+', () => { this.vm.zoomIn() })
          this.ctrlButton('›', () => { this.vm.swipeNext() })
        }
        .margin({ top: 6 })

        Row({ space: 6 }) {
          this.ctrlButton('⟲', () => { this.vm.reset() })
          this.ctrlButton(this.vm.tiltEnabled ? '◎' : '○', () => { this.vm.toggleTilt() })
        }
        .margin({ top: 6 })

        // ---- mock sensor controls ----
        Row({ space: 6 }) {
          this.ctrlButton(this.vm.mockPlaying ? '■' : '▶', () => { this.vm.toggleMock() })
          this.ctrlButton('↑', () => { this.vm.setReading(0, 9.8, 0) })    // 0°
          this.ctrlButton('→', () => { this.vm.setReading(9.8, 0, 0) })    // 90°
          this.ctrlButton('↓', () => { this.vm.setReading(0, -9.8, 0) })   // 180°
          this.ctrlButton('←', () => { this.vm.setReading(-9.8, 0, 0) })   // -90°
        }
        .margin({ top: 6 })

        // ---- manual X / Y / Z entry ----
        Row({ space: 4 }) {
          TextInput({ text: this.mx })
            .type(InputType.Normal)
            .width(42)
            .height(28)
            .fontSize(11)
            .onChange((v: string) => { this.mx = v })
          TextInput({ text: this.my })
            .type(InputType.Normal)
            .width(42)
            .height(28)
            .fontSize(11)
            .onChange((v: string) => { this.my = v })
          TextInput({ text: this.mz })
            .type(InputType.Normal)
            .width(42)
            .height(28)
            .fontSize(11)
            .onChange((v: string) => { this.mz = v })
          this.ctrlButton('✓', () => {
            this.vm.setReading(Number(this.mx) || 0, Number(this.my) || 0, Number(this.mz) || 0)
          })
        }
        .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#80000000')
      .padding(6)
      .borderRadius(10)
      .margin({ bottom: 12 })
    }
    .alignContent(Alignment.Bottom)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .focusable(true)
    .defaultFocus(true)
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PinchGesture({ fingers: 2 })
          .onActionUpdate((e: GestureEvent) => {
            this.vm.onPinch({ scale: e.scale, centerX: e.pinchCenterX, centerY: e.pinchCenterY })
          })
          .onActionEnd(() => {
            this.vm.commitPinch()
          }),
        RotationGesture({ fingers: 2 })
          .onActionUpdate((e: GestureEvent) => {
            this.vm.onRotate({ angleDelta: e.angle })
          })
          .onActionEnd(() => {
            this.vm.commitRotate()
          }),
        PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
          .onActionUpdate((e: GestureEvent) => {
            // Image follows the finger so the swipe direction is unambiguous.
            this.vm.dragX = e.offsetX
          })
          .onActionEnd((e: GestureEvent) => {
            const threshold: number = 30
            // Drag left (negative) -> next photo; drag right (positive) -> previous.
            if (e.offsetX <= -threshold) {
              this.vm.swipeNext()
            } else if (e.offsetX >= threshold) {
              this.vm.swipePrev()
            }
            animateTo({ duration: 150 }, () => {
              this.vm.dragX = 0
            })
          })
      )
    )
    .onKeyEvent((e: KeyEvent) => {
      if (e.type === KeyType.Down) {
        if (e.keyCode === Button.TOP) {
          this.vm.onButton(Button.TOP)
          return true
        }
        if (e.keyCode === Button.BOTTOM) {
          this.vm.onButton(Button.BOTTOM)
          return true
        }
      }
      return false
    })
  }
}
