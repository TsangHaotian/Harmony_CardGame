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

const SHAPES: number[][][][] = [
  [[[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]],[[0,0,1,0],[0,0,1,0],[0,0,1,0],[0,0,1,0]],[[0,0,0,0],[0,0,0,0],[1,1,1,1],[0,0,0,0]],[[0,1,0,0],[0,1,0,0],[0,1,0,0],[0,1,0,0]]],
  [[[1,1],[1,1]],[[1,1],[1,1]],[[1,1],[1,1]],[[1,1],[1,1]]],
  [[[0,1,0],[1,1,1],[0,0,0]],[[0,1,0],[0,1,1],[0,1,0]],[[0,0,0],[1,1,1],[0,1,0]],[[0,1,0],[1,1,0],[0,1,0]]],
  [[[1,0,0],[1,1,1],[0,0,0]],[[0,1,1],[0,1,0],[0,1,0]],[[0,0,0],[1,1,1],[0,0,1]],[[0,1,0],[0,1,0],[1,1,0]]],
  [[[0,0,1],[1,1,1],[0,0,0]],[[0,1,0],[0,1,0],[0,1,1]],[[0,0,0],[1,1,1],[1,0,0]],[[1,1,0],[0,1,0],[0,1,0]]],
  [[[0,1,1],[1,1,0],[0,0,0]],[[0,1,0],[0,1,1],[0,0,1]],[[0,0,0],[0,1,1],[1,1,0]],[[1,0,0],[1,1,0],[0,1,0]]],
  [[[1,1,0],[0,1,1],[0,0,0]],[[0,0,1],[0,1,1],[0,1,0]],[[0,0,0],[1,1,0],[0,1,1]],[[0,1,0],[1,1,0],[1,0,0]]]
];

const COLORS: string[] = ['#1A1A2E', '#44DDDD', '#FFDD44', '#AA44DD', '#DD8844', '#4444DD', '#44DD44', '#DD4444'];

@Entry
@Component
struct Tetris {
  @State board: number[] = new Array(200).fill(0);
  @State score: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State paused: boolean = false;
  @State bestScore: number = AppStorage.get<number>('BestTetris') ?? 0;
  @State lastScore: number = 0;
  @State nextType: number = 0;
  @State level: number = 1;
  @State lines: number = 0;

  private cols: number = 10;
  private rows: number = 20;
  private locked: number[] = new Array(200).fill(0);
  private pieceType: number = 1;
  private pieceRow: number = 0;
  private pieceCol: number = 0;
  private pieceRot: number = 0;
  private gameTimer: number = -1;

  aboutToAppear(): void {
    this.startGame();
  }

  renderBoard(): void {
    let b: number[] = [...this.locked];
    let shape = this.getShape(this.pieceType, this.pieceRot);
    for (let r = 0; r < shape.length; r++) {
      for (let c = 0; c < shape[r].length; c++) {
        if (shape[r][c] === 0) continue;
        let br = this.pieceRow + r, bc = this.pieceCol + c;
        if (br >= 0 && br < this.rows && bc >= 0 && bc < this.cols) {
          b[br * this.cols + bc] = this.pieceType;
        }
      }
    }
    this.board = b;
  }

  startGame(): void {
    this.locked = new Array(200).fill(0);
    this.score = 0;
    this.level = 1;
    this.lines = 0;
    this.gameOver = false;
    this.showOverlay = false;
    this.paused = false;
    this.lastScore = 0;
    this.nextType = Math.floor(Math.random() * 7) + 1;
    this.spawnPiece();
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    this.gameTimer = setInterval(() => { this.tick(); }, 800);
  }

  spawnPiece(): void {
    this.pieceType = this.nextType;
    this.nextType = Math.floor(Math.random() * 7) + 1;
    this.pieceRow = 0;
    this.pieceCol = Math.floor((this.cols - SHAPES[this.pieceType - 1][0].length) / 2);
    this.pieceRot = 0;
    if (!this.isValid(this.pieceRow, this.pieceCol, this.pieceRot)) {
      this.gameOver = true;
      this.endGame();
    }
    this.renderBoard();
  }

  getShape(type: number, rot: number): number[][] {
    return SHAPES[type - 1][rot % 4];
  }

  isValid(row: number, col: number, rot: number): boolean {
    let shape = this.getShape(this.pieceType, rot);
    for (let r = 0; r < shape.length; r++) {
      for (let c = 0; c < shape[r].length; c++) {
        if (shape[r][c] === 0) continue;
        let br = row + r, bc = col + c;
        if (bc < 0 || bc >= this.cols || br >= this.rows) return false;
        if (br >= 0 && this.locked[br * this.cols + bc] !== 0) return false;
      }
    }
    return true;
  }

  lockPiece(): void {
    let shape = this.getShape(this.pieceType, this.pieceRot);
    for (let r = 0; r < shape.length; r++) {
      for (let c = 0; c < shape[r].length; c++) {
        if (shape[r][c] === 0) continue;
        let br = this.pieceRow + r, bc = this.pieceCol + c;
        if (br >= 0 && br < this.rows && bc >= 0 && bc < this.cols) {
          this.locked[br * this.cols + bc] = this.pieceType;
        }
      }
    }
    this.clearLines();
    this.spawnPiece();
  }

  clearLines(): void {
    let cleared = 0;
    for (let r = this.rows - 1; r >= 0; r--) {
      let full = true;
      for (let c = 0; c < this.cols; c++) { if (this.locked[r * this.cols + c] === 0) { full = false; break; } }
      if (full) {
        for (let r2 = r; r2 > 0; r2--) { for (let c = 0; c < this.cols; c++) { this.locked[r2 * this.cols + c] = this.locked[(r2 - 1) * this.cols + c]; } }
        for (let c = 0; c < this.cols; c++) this.locked[c] = 0;
        cleared++; r++;
      }
    }
    if (cleared > 0) {
      let pts = [0, 100, 300, 500, 800];
      this.score += pts[Math.min(cleared, 4)];
      this.lines += cleared;
      this.level = Math.floor(this.lines / 3) + 1;
      let speed = Math.max(100, 800 - (this.level - 1) * 70);
      if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
      this.gameTimer = setInterval(() => { this.tick(); }, speed);
      playClick();
    }
  }

  tick(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    if (this.isValid(this.pieceRow + 1, this.pieceCol, this.pieceRot)) {
      this.pieceRow++;
    } else {
      this.lockPiece();
    }
    this.renderBoard();
  }

  endGame(): void {
    playClick();
      try { vibrator.vibrate(300); } catch (_) {};
    this.lastScore = this.score;
    if (this.score > this.bestScore) { this.bestScore = this.score; AppStorage.set<number>('BestTetris', this.bestScore); }
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    setTimeout(() => { this.showOverlay = true; }, 300);
  }

  build() {
    Column() {
      Column() {
        Scroll() {
        Column() {
        Column() {
          Column() {
            Column() {
              Row() {
                Text('俄罗斯方块').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('得分: ' + this.score.toString()).fontSize(12).fontColor('#8B8B9E')
              }.width('100%')

              Row() {
                Text('BEST  ' + this.bestScore.toString()).fontSize(11).fontColor('#FFD700').fontWeight(FontWeight.Bold)
                Text('  LAST  ' + this.lastScore.toString()).fontSize(11).fontColor('#8B8B9E').margin({ left: 8 })
                Blank()
                Text('NEXT').fontSize(11).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
              }.width('100%').margin({ bottom: 4 })
            }.width('100%')

            Stack() {
              Row() {
                Grid() {
                  ForEach(this.board, (_v: number, i: number) => {
                    GridItem() {
                      Stack() { Text(' ').fontSize(8).width('100%').height('100%') }
                      .width('100%').height('100%')
                      .backgroundColor(COLORS[this.board[i]])
                      .borderRadius(2)
                    }
                  }, (i: number) => i.toString())
                }
                .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                .columnsGap(1).rowsGap(1)
                .width('70%').height('100%')
                .border({ width: 2, color: '#555555', style: BorderStyle.Solid })

                // 右侧边框线
                Row() {}.width(2).height('90%').backgroundColor('#444444').alignSelf(ItemAlign.Center)

                Column() {
                  Text('下一个方块').fontSize(9).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                    .width('100%').textAlign(TextAlign.Center)
                  Stack() {
                    Image($r('app.media.tetris_' + (this.nextType === 1 ? 'i' : this.nextType === 2 ? 'o' : this.nextType === 3 ? 't' : this.nextType === 4 ? 'l' : this.nextType === 5 ? 'j' : this.nextType === 6 ? 's' : 'z')))
                      .width(64).height(64).objectFit(ImageFit.Contain)
                  }
                  .width('100%').layoutWeight(1)
                }
                .width('28%').height('100%').padding({ left: 4, right: 2 })
                Text('Lv.' + this.level.toString()).fontSize(9).fontColor('#888888').width('100%').textAlign(TextAlign.Center).margin({ top: 2 })
              }
              .width('100%').height('100%')

              if (this.showOverlay) {
                Column() {
                  Text('游戏结束').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text('得分: ' + this.score.toString()).fontSize(18).fontColor('#FF6B35').margin({ top: 6 })
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 10 })
                  .onClick(() => { this.startGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#AA000000')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%').height(450).backgroundColor('#1A1A2E').borderRadius(8)
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
      .onClick(() => { this.doRotate(); playClick(); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.moveDown(); playClick(); })
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
      .onClick(() => { this.paused = !this.paused; playClick(); })
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => {
        if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { this.doDrop(); playClick(); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { this.doRotate(); playClick(); })
    }
  }

  doRotate(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    let nr = (this.pieceRot + 1) % 4;
    if (this.isValid(this.pieceRow, this.pieceCol, nr)) {
      this.pieceRot = nr; this.renderBoard();
    }
  }

  moveLeft(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    if (this.isValid(this.pieceRow, this.pieceCol - 1, this.pieceRot)) {
      this.pieceCol--; this.renderBoard(); playClick();
    }
  }

  moveRight(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    if (this.isValid(this.pieceRow, this.pieceCol + 1, this.pieceRot)) {
      this.pieceCol++; this.renderBoard(); playClick();
    }
  }

  moveDown(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    if (this.isValid(this.pieceRow + 1, this.pieceCol, this.pieceRot)) {
      this.pieceRow++; this.renderBoard();
    } else {
      this.lockPiece();
    }
  }

  doDrop(): void {
    if (this.gameOver || this.showOverlay || this.paused) return;
    while (this.isValid(this.pieceRow + 1, this.pieceCol, this.pieceRot)) {
      this.pieceRow++;
    }
    this.lockPiece();
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
