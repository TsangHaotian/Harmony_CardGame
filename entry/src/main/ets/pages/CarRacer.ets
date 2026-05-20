import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct CarRacer {
  @State road: number[] = [];
  @State playerCol: number = 2;
  @State score: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State obstacles: number[][] = [];

  private roadWidth: number = 5;
  private roadHeight: number = 12;
  private gameTimer: number = -1;
  private spawnTimer: number = -1;
  private speed: number = 300;

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.score = 0;
    this.playerCol = 2;
    this.gameOver = false;
    this.showOverlay = false;
    this.obstacles = [];
    this.speed = 300;
    this.buildRoad();
    if (this.gameTimer > 0) {
      clearInterval(this.gameTimer);
    }
    if (this.spawnTimer > 0) {
      clearInterval(this.spawnTimer);
    }
    this.gameTimer = setInterval(() => {
      this.tick();
    }, this.speed);
    this.spawnTimer = setInterval(() => {
      this.spawnObstacle();
    }, 1200);
  }

  buildRoad(): void {
    let r: number[] = [];
    for (let i = 0; i < this.roadHeight * this.roadWidth; i++) {
      r.push(0);
    }
    this.road = r;
  }

  spawnObstacle(): void {
    if (this.gameOver || this.showOverlay) { return; }
    let col = Math.floor(Math.random() * this.roadWidth);
    this.obstacles.push([0, col]);
  }

  tick(): void {
    if (this.gameOver || this.showOverlay) { return; }

    // move obstacles down
    for (let i = this.obstacles.length - 1; i >= 0; i--) {
      this.obstacles[i][0]++;
      if (this.obstacles[i][0] >= this.roadHeight) {
        this.obstacles.splice(i, 1);
        this.score++;
        if (this.score % 5 === 0 && this.speed > 150) {
          this.speed -= 20;
          if (this.gameTimer > 0) {
            clearInterval(this.gameTimer);
          }
          this.gameTimer = setInterval(() => {
            this.tick();
          }, this.speed);
        }
      }
    }

    // check collision
    for (let i = 0; i < this.obstacles.length; i++) {
      let row = this.obstacles[i][0];
      let col = this.obstacles[i][1];
      if (row >= this.roadHeight - 2 && col === this.playerCol) {
        this.endGame();
        return;
      }
    }

    this.renderRoad();
  }

  renderRoad(): void {
    let r: number[] = [];
    for (let i = 0; i < this.roadHeight * this.roadWidth; i++) {
      r.push(0);
    }
    // draw obstacles
    for (let i = 0; i < this.obstacles.length; i++) {
      let row = this.obstacles[i][0];
      let col = this.obstacles[i][1];
      if (row >= 0 && row < this.roadHeight) {
        r[row * this.roadWidth + col] = 1;
      }
    }
    // draw player car
    let playerRow = this.roadHeight - 1;
    r[playerRow * this.roadWidth + this.playerCol] = 2;
    this.road = r;
  }

  moveLeft(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol > 0) {
      this.playerCol--;
      this.renderRoad();
    }
  }

  moveRight(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol < this.roadWidth - 1) {
      this.playerCol++;
      this.renderRoad();
    }
  }

  endGame(): void {
    this.gameOver = true;
    vibrate(300);
    if (this.gameTimer > 0) {
      clearInterval(this.gameTimer);
      this.gameTimer = -1;
    }
    if (this.spawnTimer > 0) {
      clearInterval(this.spawnTimer);
      this.spawnTimer = -1;
    }
    setTimeout(() => { this.showOverlay = true; }, 200);
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
          if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
          if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); }
          try {
            this.getUIContext().getRouter().back();
          } catch (_) {}
        })

        Text('赛车大赛')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')

        Text('得分: ' + this.score.toString())
          .fontSize(16)
          .fontColor('#776E65')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // Road grid with overlay
      Stack() {
        Grid() {
          ForEach(this.road, (v: number, index: number) => {
            GridItem() {
              Stack() {
                if (v === 0) {
                  if (index % this.roadWidth === 2) {
                    Text('')
                      .width(4)
                      .height('100%')
                      .backgroundColor('#FFFFFF')
                      .opacity(0.3)
                  }
                } else if (v === 1) {
                  Text('')
                    .width('80%')
                    .height('80%')
                    .backgroundColor('#CC4444')
                    .borderRadius(4)
                } else if (v === 2) {
                  Text('')
                    .width('80%')
                    .height('80%')
                    .backgroundColor('#4488CC')
                    .borderRadius(4)
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#555555')
            }
          }, (index: number) => index.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(2)
        .rowsGap(2)
        .width(200)
        .height(450)
        .backgroundColor('#444444')
        .borderRadius(8)
        .padding(4)

        if (this.showOverlay) {
          Column() {
            Text('撞车了！')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#776E65')
            Text('得分: ' + this.score.toString())
              .fontSize(24)
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
          .width(200)
          .height(450)
          .backgroundColor('#BAEEE4DA')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .borderRadius(8)
        }
      }
      .width(200)
      .height(450)

      Row() {
        Button() {
          Text('←')
            .fontSize(28)
            .fontColor('#F9F6F2')
        }
        .backgroundColor('#8F7A66')
        .borderRadius(8)
        .width(80)
        .height(56)
        .onClick(() => {
          this.moveLeft();
        })

        Button() {
          Text('→')
            .fontSize(28)
            .fontColor('#F9F6F2')
        }
        .backgroundColor('#8F7A66')
        .borderRadius(8)
        .width(80)
        .height(56)
        .margin({ left: 20 })
        .onClick(() => {
          this.moveRight();
        })
      }
      .padding({ top: 12 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
