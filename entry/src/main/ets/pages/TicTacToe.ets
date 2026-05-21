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
struct TicTacToe {
  @State board: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State playerTurn: boolean = true;
  @State winner: number = 0;
  @State draw: boolean = false;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State bestScore: number = AppStorage.get<number>('BestTicTac') ?? 0;
  @State lastScore: number = 0;
  @State cursor: number = 4;
  @State score: number = 0;

  aboutToAppear(): void {
    this.newGame();
  }

  newGame(): void {
    this.board = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    this.playerTurn = true;
    this.winner = 0;
    this.draw = false;
    this.gameOver = false;
    this.showOverlay = false;
    this.cursor = 4;
  }

  checkWin(b: number[], p: number): boolean {
    let wins = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (let i = 0; i < wins.length; i++) { if (b[wins[i][0]] === p && b[wins[i][1]] === p && b[wins[i][2]] === p) return true; }
    return false;
  }

  aiMove(): void {
    if (this.gameOver || this.showOverlay) return;
    for (let i = 0; i < 9; i++) {
      if (this.board[i] === 0) { let b = [...this.board]; b[i] = 2; if (this.checkWin(b, 2)) { this.place(i, 2); return; } }
    }
    for (let i = 0; i < 9; i++) {
      if (this.board[i] === 0) { let b = [...this.board]; b[i] = 1; if (this.checkWin(b, 1)) { this.place(i, 2); return; } }
    }
    if (this.board[4] === 0) { this.place(4, 2); return; }
    let corners = [0, 2, 6, 8];
    for (let i = 0; i < corners.length; i++) { let c = corners[i]; if (this.board[c] === 1) { let opp = 8 - c; if (this.board[opp] === 0) { this.place(opp, 2); return; } } }
    let empty: number[] = [];
    for (let i = 0; i < 9; i++) { if (this.board[i] === 0) empty.push(i); }
    if (empty.length > 0) this.place(empty[Math.floor(Math.random() * empty.length)], 2);
  }

  place(idx: number, p: number): void {
    let b = [...this.board]; b[idx] = p; this.board = b;
    if (this.checkWin(b, p)) {
      this.winner = p; this.gameOver = true; this.lastScore = p === 1 ? 1 : 0;
      if (p === 1) { this.score++; if (this.score > this.bestScore) { this.bestScore = this.score; AppStorage.set<number>('BestTicTac', this.bestScore); } }
      setTimeout(() => { this.showOverlay = true; }, 300); return;
    }
    if (!b.includes(0)) { this.draw = true; this.gameOver = true; setTimeout(() => { this.showOverlay = true; }, 300); return; }
    this.playerTurn = !this.playerTurn;
    if (!this.playerTurn && !this.gameOver) { setTimeout(() => { this.aiMove(); }, 200); }
  }

  cellClick(idx: number): void {
    if (this.gameOver || this.showOverlay || !this.playerTurn || this.board[idx] !== 0) return;
    playClick();
    this.place(idx, 1);
  }

  moveCursor(n: number): void {
    if (this.gameOver || this.showOverlay) return;
    let nc = this.cursor + n;
    if (nc < 0 || nc > 8) { this.cursor = nc < 0 ? 8 : 0; playClick(); return; }
    this.cursor = nc; playClick();
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Column() {
              Row() {
                Text('井字棋').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
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
                      Text(v === 1 ? '✗' : v === 2 ? '○' : '').fontSize(48)
                        .fontColor(v === 1 ? '#CC4444' : '#4488CC').fontWeight(FontWeight.Bold)
                        .width('100%').height('100%').textAlign(TextAlign.Center)
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cursor === i && !this.gameOver ? '#334455' : '#1A1A2E')
                    .border({ width: 1, color: '#444444', style: BorderStyle.Solid })
                  }
                  .onClick(() => { this.cellClick(i); })
                }, (i: number) => i.toString())
              }
              .columnsTemplate('1fr 1fr 1fr').rowsTemplate('1fr 1fr 1fr')
              .columnsGap(0).rowsGap(0).width('85%').aspectRatio(1).alignSelf(ItemAlign.Center)

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
            .width('85%').aspectRatio(1).alignSelf(ItemAlign.Center)
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
      .onClick(() => { this.moveCursor(-3); playClick(); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.moveCursor(3); playClick(); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveCursor(-1); playClick(); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveCursor(1); playClick(); })
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
