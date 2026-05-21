import vibrator from '@ohos.vibrator';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

let soundPool: media.SoundPool | null = null;
let soundId: number = 0;
let soundReady: boolean = false;

function initSound(): void {
  try {
    let info: audio.AudioRendererInfo = { usage: audio.StreamUsage.STREAM_USAGE_MUSIC, rendererFlags: 0 };
    media.createSoundPool(3, info).then((pool: media.SoundPool) => {
      soundPool = pool;
      let ctx = getContext();
      let rawFd = ctx.resourceManager.getRawFdSync('click.mp3');
      pool.load(rawFd.fd, rawFd.offset, rawFd.length).then((id: number) => {
        soundId = id;
        soundReady = true;
      });
    });
  } catch (_) {}
}
initSound();

function playClick(): void {
  try { vibrator.vibrate(8); } catch (_) {}
  if (soundReady && soundPool) {
    try { soundPool.play(soundId, { loop: 0, leftVolume: 1.0, rightVolume: 1.0 }); } catch (_) {}
  }
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
  @StorageLink('BestRacer') bestScore: number = 0;
  @State lastScore: number = 0;
  private roadWidth: number = 12;
  private roadHeight: number = 24;
  private gameTimer: number = -1;
  private spawnTimer: number = -1;
  private speed: number = 180;

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.score = 0;
    this.lastScore = 0;
    this.playerCol = 5;
    this.gameOver = false;
    this.showOverlay = false;
    this.obstacles = [];
    this.speed = 280;
    this.buildRoad();
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
    if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); }
    this.gameTimer = setInterval(() => { this.tick(); }, this.speed);
    this.spawnTimer = setInterval(() => { this.spawnObstacle(); }, 1000);
  }

  buildRoad(): void {
    let r: number[] = [];
    for (let i = 0; i < this.roadHeight * this.roadWidth; i++) { r.push(0); }
    this.road = r;
  }

  spawnObstacle(): void {
    if (this.gameOver || this.showOverlay) { return; }
    let col = Math.floor(Math.random() * (this.roadWidth - 2)) + 1;
    if (this.roadHeight <= 14) { col = Math.floor(Math.random() * (this.roadWidth - 2)) + 1; }
    this.obstacles.push([0, col]);
  }

  tick(): void {
    if (this.gameOver || this.showOverlay) { return; }
    for (let i = this.obstacles.length - 1; i >= 0; i--) {
      this.obstacles[i][0]++;
      if (this.obstacles[i][0] >= this.roadHeight) {
        this.obstacles.splice(i, 1);
        this.score++;
        if (this.score % 5 === 0 && this.speed > 120) {
          this.speed -= 15;
          if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
          this.gameTimer = setInterval(() => { this.tick(); }, this.speed);
        }
      }
    }
    for (let i = 0; i < this.obstacles.length; i++) {
      if (this.obstacles[i][0] >= this.roadHeight - 2 && this.obstacles[i][1] === this.playerCol) {
        this.endGame();
        return;
      }
    }
    this.renderRoad();
  }

  renderRoad(): void {
    let r: number[] = new Array(this.roadHeight * this.roadWidth).fill(0);
    let mid = Math.floor((this.roadWidth - 1) / 2);
    for (let row = 0; row < this.roadHeight; row++) {
      for (let col = 0; col < this.roadWidth; col++) {
        if (col === 0 || col === this.roadWidth - 1) {
          r[row * this.roadWidth + col] = 4; // shoulder
        } else if (col === mid) {
          r[row * this.roadWidth + col] = (row % 2 === 0) ? 3 : 2; // center line dashed
        } else {
          r[row * this.roadWidth + col] = 2; // road
        }
      }
    }
    for (let i = 0; i < this.obstacles.length; i++) {
      let row = this.obstacles[i][0];
      let col = this.obstacles[i][1];
      if (row >= 0 && row < this.roadHeight) { r[row * this.roadWidth + col] = 10; }
    }
    let playerRow = this.roadHeight - 2;
    r[playerRow * this.roadWidth + this.playerCol] = 20;
    this.road = r;
  }

  moveLeft(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol > 1) { this.playerCol--; this.renderRoad(); playClick(); }
  }

  moveRight(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol < this.roadWidth - 2) { this.playerCol++; this.renderRoad(); playClick(); }
  }


  endGame(): void {
    this.gameOver = true;
    playClick();
      try { vibrator.vibrate(300); } catch (_) {}
    this.lastScore = this.score;
    if (this.score > this.bestScore) { this.bestScore = this.score; }
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); this.spawnTimer = -1; }
    setTimeout(() => { this.showOverlay = true; }, 300);
  }

  cellBg(v: number): string {
    if (v === 1) { return '#EEEEEE'; }
    if (v === 2) { return '#555555'; }
    if (v === 3) { return '#AAAAAA'; }
    if (v === 4) { return '#333333'; }                       // shoulder
    if (v >= 10 && v <= 13) { return '#CC4444'; }          // obstacle
    if (v === 20) { return '#EEEEEE'; }                     // player
    return '#555555';
  }

  build() {
    Column() {
      Column() {
        Scroll() {
        Column() {
        Column() {
          Column() {
            // Scoreboard area (top)
            Column() {
              Row() {
                Text('赛车大赛').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('得分: ' + this.score.toString()).fontSize(12).fontColor('#8B8B9E')
              }
              .width('100%')

              Column() {
                Text('BEST  ' + this.bestScore.toString())
                  .fontSize(13).fontColor('#FFD700').fontWeight(FontWeight.Bold)
                Text('LAST  ' + this.lastScore.toString())
                  .fontSize(13).fontColor('#8B8B9E')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .layoutWeight(1)
            }
            .width('100%')
            .layoutWeight(1)

            // Game grid (bottom)
            Stack() {
              Grid() {
                ForEach(this.road, (v: number, index: number) => {
                  GridItem() {
                    Stack() {
                      if (v === 20) {
                        // Player car — simple triangle/arrow shape
                        Row() {
                          Text('▲').fontSize(11).fontColor('#333333').fontWeight(FontWeight.Bold)
                        }
                        .width('100%').height('100%')
                        .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cellBg(v))
                    .borderRadius(v >= 10 ? 4 : 0)
                  }
                }, (index: number) => index.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(0).rowsGap(0)
              .width('100%').height('100%')

              if (this.showOverlay) {
                Column() {
                  Text('撞车了！').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text('得分: ' + this.score.toString()).fontSize(20).fontColor('#FF6B35').margin({ top: 8 })
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 12 })
                  .onClick(() => { this.startGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#AA000000')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('80%')
            .constraintSize({ maxHeight: 380 })
            .aspectRatio(0.5)
            .alignSelf(ItemAlign.Center)
          }
          .width('100%').backgroundColor('#1A1A2E').borderRadius(8)
          .height(450)
          .clip(true)
          .padding({ top: 10, bottom: 8, left: 12, right: 12 })
        }
        .backgroundColor('#444444').borderRadius(12).padding(8)
        .margin({ top: 20, left: 16, right: 16 })

        Row() { this.StartSelectLayout() }.padding({ top: 14, bottom: 4 })

        Row() {
          this.DPadLayout()
          Blank().layoutWeight(1)
          this.ActionButtonLayout()
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 16, right: 24, bottom: 4 })

        Text('HARMONY GB').fontSize(11).fontColor('#888888').margin({ bottom: 6 })
      }
      }
      }
      .width('92%').layoutWeight(1).constraintSize({ maxWidth: 540 }).backgroundColor('#D4D0C8').borderRadius(24)
    }
    .width('100%').height('100%').backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center).padding({ top: 40, bottom: 15 })
  }

  @Builder DPadLayout() {
    Stack() {
      Button() { Image($r('app.media.icon_up')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: -42 })
      .onClick(() => { playClick(); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { playClick(); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveLeft(); playClick(); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveRight(); playClick(); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.startGame(); })
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => {
        if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
        if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); }
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => {
        if (!this.gameOver && !this.showOverlay) {
          this.moveLeft();
          playClick();
        }
      })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => {
        if (!this.gameOver && !this.showOverlay) {
          this.moveRight();
          playClick();
        }
      })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
