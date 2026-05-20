import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct WhackAMole {
  @State holes: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State score: number = 0;
  @State timeLeft: number = 30;
  @State playing: boolean = false;
  @State showOverlay: boolean = false;

  private timerInterval: number = -1;
  private moleInterval: number = -1;

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.score = 0;
    this.timeLeft = 30;
    this.showOverlay = false;
    this.playing = true;
    this.holes = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    if (this.timerInterval > 0) {
      clearInterval(this.timerInterval);
    }
    if (this.moleInterval > 0) {
      clearInterval(this.moleInterval);
    }
    this.timerInterval = setInterval(() => {
      this.timeLeft--;
      if (this.timeLeft <= 0) {
        this.endGame();
      }
    }, 1000);
    this.spawnMole();
    this.moleInterval = setInterval(() => {
      this.spawnMole();
    }, 800);
  }

  spawnMole(): void {
    if (!this.playing) { return; }
    let hideIdx = Math.floor(Math.random() * 9);
    this.holes[hideIdx] = 0;
    let available: number[] = [];
    for (let i = 0; i < 9; i++) {
      if (this.holes[i] === 0) {
        available.push(i);
      }
    }
    if (available.length > 0) {
      let idx = available[Math.floor(Math.random() * available.length)];
      this.holes[idx] = 1;
    }
    this.holes = [...this.holes];
  }

  whack(index: number): void {
    if (!this.playing || this.showOverlay) { return; }
    if (this.holes[index] === 1) {
      this.score++;
      this.holes[index] = 0;
      this.holes = [...this.holes];
      vibrate(20);
    } else {
      vibrate(5);
    }
  }

  endGame(): void {
    this.playing = false;
    vibrate(200);
    if (this.timerInterval > 0) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }
    if (this.moleInterval > 0) {
      clearInterval(this.moleInterval);
      this.moleInterval = -1;
    }
    this.showOverlay = true;
  }

  build() {
    Column() {
      Blank()

      Row() {
        Button() {
          Text('← 返回')
            .fontSize(16)
            .fontColor('#776E65')
        }
        .backgroundColor('transparent')
        .onClick(() => {
          this.endGame();
          try {
            this.getUIContext().getRouter().back();
          } catch (_) {}
        })

        Text('打地鼠')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')

        Button() {
          Text('重来')
            .fontSize(16)
            .fontColor('#F9F6F2')
        }
        .backgroundColor('#8F7A66')
        .borderRadius(8)
        .width(72)
        .height(40)
        .onClick(() => {
          this.startGame();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      Row() {
        Text('得分: ' + this.score.toString())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')
        Text('时间: ' + this.timeLeft.toString() + 's')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#CC4444')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ bottom: 16 })

      Grid() {
        ForEach(this.holes, (value: number, index: number) => {
          GridItem() {
            Stack() {
              Circle()
                .width(72)
                .height(72)
                .fill('#CDC1B4')
              if (value === 1) {
                Circle()
                  .width(64)
                  .height(64)
                  .fill('#F67C5F')
                Text('!')
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
            }
            .width(80)
            .height(80)
          }
          .onClick(() => {
            this.whack(index);
          })
        }, (index: number) => index.toString())
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width(270)
      .height(270)
      .backgroundColor('#BBADA0')
      .borderRadius(12)
      .padding(8)

      if (this.showOverlay) {
        Column() {
          Text('时间到！')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#776E65')
          Text('得分: ' + this.score.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#CC4444')
            .margin({ top: 8 })
          Button() {
            Text('再来一局')
              .fontSize(16)
              .fontColor('#F9F6F2')
          }
          .backgroundColor('#8F7A66')
          .borderRadius(8)
          .margin({ top: 16 })
          .onClick(() => {
            this.startGame();
          })
        }
        .width(270)
        .height(270)
        .backgroundColor('#BAEEE4DA')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .borderRadius(12)
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
