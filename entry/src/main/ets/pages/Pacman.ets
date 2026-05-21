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
struct Pacman {
  @State grid: number[] = [];
  @State seconds: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State bestScore: number = AppStorage.get<number>('BestPacman') ?? 0;
  @State lastScore: number = 0;

  private cols: number = 19;
  private rows: number = 19;
  private pRow: number = 1;
  private pCol: number = 1;
  private dir: number = 0;
  private nextDir: number = 0;
  private foodCount: number = 0;
  private stepCount: number = 0;
  private timerInterval: number = -1;
  private maze: number[] = [];

  aboutToAppear(): void {
    this.startGame();
  }

  buildMaze(): void {
    let m: number[] = new Array(this.rows * this.cols).fill(0);
    // Outer walls
    for (let r = 0; r < this.rows; r++) {
      for (let c = 0; c < this.cols; c++) {
        if (r === 0 || r === this.rows - 1 || c === 0 || c === this.cols - 1) {
          m[r * this.cols + c] = 0;
        } else {
          m[r * this.cols + c] = 1;
        }
      }
    }
    // Random walls (about 20%)
    let wallCount = Math.floor((this.rows - 2) * (this.cols - 2) * 0.2);
    for (let w = 0; w < wallCount; w++) {
      let r = Math.floor(Math.random() * (this.rows - 2)) + 1;
      let c = Math.floor(Math.random() * (this.cols - 2)) + 1;
      // Don't block the starting position
      if (r === 1 && c === 1) continue;
      m[r * this.cols + c] = 0;
    }
    this.maze = m;
    this.foodCount = 0;
    for (let i = 0; i < m.length; i++) { if (m[i] === 1) this.foodCount++; }
  }

  startGame(): void {
    this.pRow = 1; this.pCol = 1; this.dir = 0;
    this.seconds = 0; this.stepCount = 0;
    this.gameOver = false; this.showOverlay = false; this.lastScore = 0;
    this.buildMaze();
    this.renderGrid();
    if (this.timerInterval > 0) { clearInterval(this.timerInterval); }
    this.timerInterval = setInterval(() => { if (!this.gameOver && !this.showOverlay) this.seconds++; }, 1000);
  }

  tick(): void {
    if (this.gameOver || this.showOverlay) return;
    // Only move when a direction key was pressed — manual step
    this.renderGrid();
  }

  moveDir(d: number): void {
    if (this.gameOver || this.showOverlay) return;
    let nr = this.pRow, nc = this.pCol;
    if (d === 0) nc++; else if (d === 1) nr++; else if (d === 2) nc--; else nr--;
    if (nc >= 0 && nc < this.cols && nr >= 0 && nr < this.rows && this.maze[nr * this.cols + nc] !== 0) {
      this.dir = d; this.pRow = nr; this.pCol = nc; this.stepCount++;
      let idx = this.pRow * this.cols + this.pCol;
      if (this.maze[idx] === 1) {
        this.maze[idx] = 2; this.foodCount--;
        playClick();
        if (this.foodCount <= 0) { this.endGame(); return; }
      }
      this.renderGrid();
    }
  }

  renderGrid(): void {
    let g: number[] = [];
    for (let i = 0; i < this.maze.length; i++) {
      if (this.maze[i] === 0) g.push(0);
      else if (this.maze[i] === 1) g.push(1);
      else g.push(2);
    }
    g[this.pRow * this.cols + this.pCol] = 3;
    this.grid = g;
  }

  changeDir(d: number): void {
    if (this.gameOver || this.showOverlay) return;
    this.nextDir = d;
  }

  endGame(): void {
    this.gameOver = true;
    this.lastScore = this.seconds;
    if (this.bestScore === 0 || this.seconds < this.bestScore) { this.bestScore = this.seconds; AppStorage.set<number>('BestPacman', this.bestScore); }
    if (this.timerInterval > 0) { clearInterval(this.timerInterval); }
    setTimeout(() => { this.showOverlay = true; }, 300);
  }

  cellBg(v: number): string {
    if (v === 0) return '#1A1A2E';
    if (v === 1) return '#FFDD44';
    if (v === 2) return '#1A1A2E';
    if (v === 3) return '#FFDD44';
    return '#1A1A2E';
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Column() {
              Row() {
                Text('吃豆人').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('时间: ' + this.seconds.toString() + 's').fontSize(12).fontColor('#8B8B9E')
              }.width('100%')
              Column() {
                Text('BEST  ' + this.bestScore.toString() + 's').fontSize(13).fontColor('#FFD700').fontWeight(FontWeight.Bold)
                Text('LAST  ' + this.lastScore.toString() + 's').fontSize(13).fontColor('#8B8B9E')
              }
              .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).layoutWeight(1)
            }
            .width('100%').layoutWeight(1)

            Stack() {
              Grid() {
                ForEach(this.grid, (v: number, i: number) => {
                  GridItem() {
                    Stack() {
                      if (v === 1) {
                        Circle().width('30%').height('30%').fill('#FFDD44')
                      } else if (v === 3) {
                        Circle().width('60%').height('60%').fill('#FFDD44')
                          .shadow({ radius: 4, color: '#CC8800' })
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(v === 0 ? '#2222AA' : '#1A1A2E')
                    .borderRadius(v === 3 ? 6 : 0)
                  }
                }, (i: number) => i.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(0).rowsGap(0).width('98%').aspectRatio(1).alignSelf(ItemAlign.Center)

              if (this.showOverlay) {
                Column() {
                  Text(this.foodCount <= 0 ? '通关！' : '游戏结束').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text('用时: ' + this.seconds.toString() + 's').fontSize(20).fontColor('#FF6B35').margin({ top: 8 })
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 12 })
                  .onClick(() => { this.startGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#AA000000')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('95%').aspectRatio(1).alignSelf(ItemAlign.Center)
          }
          .width('100%').height(450).backgroundColor('#1A1A2E').borderRadius(8).clip(true)
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
      .width('92%').layoutWeight(1).constraintSize({ maxWidth: 540 }).backgroundColor('#D4D0C8').borderRadius(24)
    }
    .width('100%').height('100%').backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center).padding({ top: 40, bottom: 15 })
  }

  @Builder DPadLayout() {
    Stack() {
      Button() { Image($r('app.media.icon_up')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: -42 })
      .onClick(() => { this.moveDir(3); playClick(); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.moveDir(1); playClick(); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveDir(2); playClick(); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveDir(0); playClick(); })
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
      .onClick(() => { if (this.timerInterval > 0) { clearInterval(this.timerInterval); } try { this.getUIContext().getRouter().back(); } catch (_) {} })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { playClick(); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { playClick(); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
