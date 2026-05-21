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
struct Gomoku {
  @State board: number[] = new Array(225).fill(0);
  @State playerTurn: boolean = true;
  @State winner: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State bestScore: number = AppStorage.get<number>('BestGomoku') ?? 0;
  @State lastScore: number = 0;
  @State cursor: number = 112;
  @State score: number = 0;

  private gridSize: number = 15;

  aboutToAppear(): void {
    this.newGame();
  }

  newGame(): void {
    this.board = new Array(225).fill(0);
    this.playerTurn = true;
    this.winner = 0;
    this.gameOver = false;
    this.showOverlay = false;
    this.cursor = 112;
  }

  checkWin(b: number[], p: number, idx: number): boolean {
    let r = Math.floor(idx / this.gridSize);
    let c = idx % this.gridSize;
    const dirs = [[1,0],[0,1],[1,1],[1,-1]];
    for (let d of dirs) {
      let count = 1;
      for (let s = 1; s < 5; s++) {
        let nr = r + d[0] * s, nc = c + d[1] * s;
        if (nr < 0 || nr >= this.gridSize || nc < 0 || nc >= this.gridSize || b[nr * this.gridSize + nc] !== p) break;
        count++;
      }
      for (let s = 1; s < 5; s++) {
        let nr = r - d[0] * s, nc = c - d[1] * s;
        if (nr < 0 || nr >= this.gridSize || nc < 0 || nc >= this.gridSize || b[nr * this.gridSize + nc] !== p) break;
        count++;
      }
      if (count >= 5) return true;
    }
    return false;
  }

  aiMove(): void {
    if (this.gameOver || this.showOverlay) return;
    let best = -1, bestScore = 0;
    for (let i = 0; i < 225; i++) {
      if (this.board[i] !== 0) continue;
      let s = this.evaluatePos(i, 2) + this.evaluatePos(i, 1) * 0.9;
      if (s > bestScore) { bestScore = s; best = i; }
    }
    if (best >= 0) this.place(best, 2);
    else { let empty: number[] = [];
      for (let i = 0; i < 225; i++) { if (this.board[i] === 0) empty.push(i); }
      if (empty.length > 0) this.place(empty[Math.floor(Math.random() * empty.length)], 2);
    }
  }

  evaluatePos(idx: number, p: number): number {
    let r = Math.floor(idx / this.gridSize), c = idx % this.gridSize;
    let score = 0;
    const dirs = [[1,0],[0,1],[1,1],[1,-1]];
    for (let d of dirs) {
      let count = 1;
      for (let s = 1; s < 5; s++) {
        let nr = r + d[0] * s, nc = c + d[1] * s;
        if (nr < 0 || nr >= this.gridSize || nc < 0 || nc >= this.gridSize || this.board[nr * this.gridSize + nc] !== p) break;
        count++;
      }
      for (let s = 1; s < 5; s++) {
        let nr = r - d[0] * s, nc = c - d[1] * s;
        if (nr < 0 || nr >= this.gridSize || nc < 0 || nc >= this.gridSize || this.board[nr * this.gridSize + nc] !== p) break;
        count++;
      }
      if (count >= 5) score += 10000;
      else if (count === 4) score += 1000;
      else if (count === 3) score += 100;
      else if (count === 2) score += 10;
    }
    return score;
  }

  place(idx: number, p: number): void {
    let b = [...this.board]; b[idx] = p; this.board = b;
    if (this.checkWin(b, p, idx)) {
      this.winner = p; this.gameOver = true; this.lastScore = p === 1 ? 1 : 0;
      if (p === 1) { this.score++; if (this.score > this.bestScore) { this.bestScore = this.score; AppStorage.set<number>('BestGomoku', this.bestScore); } }
      setTimeout(() => { this.showOverlay = true; }, 300); return;
    }
    this.playerTurn = !this.playerTurn;
    if (!this.playerTurn && !this.gameOver) { setTimeout(() => { this.aiMove(); }, 100); }
  }

  cellClick(idx: number): void {
    if (this.gameOver || this.showOverlay || !this.playerTurn || this.board[idx] !== 0) return;
    playClick();
    this.place(idx, 1);
  }

  moveCursor(dr: number, dc: number): void {
    if (this.gameOver || this.showOverlay) return;
    let r = Math.floor(this.cursor / this.gridSize) + dr;
    let c = this.cursor % this.gridSize + dc;
    if (r < 0) r = this.gridSize - 1;
    if (r >= this.gridSize) r = 0;
    if (c < 0) c = this.gridSize - 1;
    if (c >= this.gridSize) c = 0;
    this.cursor = r * this.gridSize + c;
    playClick();
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Column() {
              Row() {
                Text('五子棋').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('胜场: ' + this.score.toString()).fontSize(12).fontColor('#8B8B9E')
              }.width('100%')
              Column() {
                Text('BEST  ' + this.bestScore.toString()).fontSize(13).fontColor('#FFD700').fontWeight(FontWeight.Bold)
                Text('LAST  ' + this.lastScore.toString()).fontSize(13).fontColor('#8B8B9E')
              }
              .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).layoutWeight(1)
            }
            .width('100%').layoutWeight(1)

            Stack() {
              Grid() {
                ForEach(this.board, (v: number, i: number) => {
                  GridItem() {
                    Stack() {
                      if (v === 1) {
                        Circle().width('70%').height('70%').fill('#222222')
                      } else if (v === 2) {
                        Circle().width('70%').height('70%').fill('#FFFFFF').border({ width: 1, color: '#CCCCCC' })
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cursor === i && !this.gameOver ? '#D4B896' : '#C8A87C')
                    .border({ width: 0.5, color: '#A08060', style: BorderStyle.Solid })
                  }
                  .onClick(() => { this.cellClick(i); })
                }, (i: number) => i.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(0).rowsGap(0).width('100%').height('100%')

              if (this.showOverlay) {
                Column() {
                  Text(this.winner === 1 ? '你赢了！' : this.winner === 2 ? 'AI赢了！' : '平局！')
                    .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 12 })
                  .onClick(() => { this.newGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#AA000000')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('100%').aspectRatio(1).constraintSize({ maxHeight: 380 }).alignSelf(ItemAlign.Center)
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
      .onClick(() => { this.moveCursor(-1, 0); playClick(); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.moveCursor(1, 0); playClick(); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveCursor(0, -1); playClick(); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveCursor(0, 1); playClick(); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.newGame(); })
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => { try { this.getUIContext().getRouter().back(); } catch (_) {} })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { playClick(); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { this.cellClick(this.cursor); playClick(); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
