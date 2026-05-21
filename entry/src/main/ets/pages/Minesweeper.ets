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
struct Minesweeper {
  @State flatCells: number[] = [];
  @State flatRevealed: boolean[] = [];
  @State flatFlagged: boolean[] = [];
  @State gameOver: boolean = false;
  @State gameWon: boolean = false;
  @State showOverlay: boolean = false;
  @State mineCount: number = 10;
  @State flagCount: number = 0;
  @State seconds: number = 0;
  @State initialized: boolean = false;
  @State flagMode: boolean = false;
  @State cursorRow: number = 0;
  @State cursorCol: number = 0;
  @StorageLink('BestMine') bestScore: number = 0;
  @State lastScore: number = 0;

  private gridSize: number = 9;
  private cells: number[][] = [];
  private revealed: boolean[][] = [];
  private flagged: boolean[][] = [];
  private timerInterval: number = -1;
  private firstClick: boolean = true;
  private readonly DIRS: number[][] = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1]
  ];

  aboutToAppear(): void {
    this.initGame();
  }

  initGame(): void {
    this.cells = [];
    this.revealed = [];
    this.flagged = [];
    for (let r = 0; r < this.gridSize; r++) {
      this.cells[r] = [];
      this.revealed[r] = [];
      this.flagged[r] = [];
      for (let c = 0; c < this.gridSize; c++) {
        this.cells[r][c] = 0;
        this.revealed[r][c] = false;
        this.flagged[r][c] = false;
      }
    }
    this.firstClick = true;
    this.gameOver = false;
    this.gameWon = false;
    this.lastScore = 0;
    this.showOverlay = false;
    this.flagCount = 0;
    this.seconds = 0;
    this.initialized = true;
    this.cursorRow = 0;
    this.cursorCol = 0;
    if (this.timerInterval > 0) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }
    this.syncFlat();
  }

  placeMines(safeR: number, safeC: number): void {
    let placed = 0;
    while (placed < this.mineCount) {
      let r = Math.floor(Math.random() * this.gridSize);
      let c = Math.floor(Math.random() * this.gridSize);
      if (this.cells[r][c] === 9) { continue; }
      if (Math.abs(r - safeR) <= 1 && Math.abs(c - safeC) <= 1) { continue; }
      this.cells[r][c] = 9;
      placed++;
    }
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.cells[r][c] === 9) { continue; }
        let count = 0;
        for (let d = 0; d < this.DIRS.length; d++) {
          let nr = r + this.DIRS[d][0];
          let nc = c + this.DIRS[d][1];
          if (nr >= 0 && nr < this.gridSize && nc >= 0 && nc < this.gridSize && this.cells[nr][nc] === 9) { count++; }
        }
        this.cells[r][c] = count;
      }
    }
  }

  syncFlat(): void {
    let cells: number[] = [];
    let revealed: boolean[] = [];
    let flagged: boolean[] = [];
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        cells.push(this.cells[r][c]);
        revealed.push(this.revealed[r][c]);
        flagged.push(this.flagged[r][c]);
      }
    }
    this.flatCells = cells;
    this.flatRevealed = revealed;
    this.flatFlagged = flagged;
  }

  reveal(r: number, c: number): void {
    if (r < 0 || r >= this.gridSize || c < 0 || c >= this.gridSize) { return; }
    if (this.revealed[r][c] || this.flagged[r][c]) { return; }
    this.revealed[r][c] = true;
    if (this.cells[r][c] === 0) {
      for (let d = 0; d < this.DIRS.length; d++) {
        this.reveal(r + this.DIRS[d][0], c + this.DIRS[d][1]);
      }
    }
  }

  handleClick(index: number): void {
    if (this.gameOver || this.gameWon || this.showOverlay) { return; }
    let r = Math.floor(index / this.gridSize);
    let c = index % this.gridSize;
    if (this.revealed[r][c]) { return; }
    if (this.flagMode) {
      this.flagged[r][c] = !this.flagged[r][c];
      this.countFlags();
      this.syncFlat();
      playClick();
      return;
    }
    if (this.flagged[r][c]) { playClick(); return; }
    if (this.firstClick) {
      this.placeMines(r, c);
      this.firstClick = false;
      if (this.timerInterval < 0) {
        this.timerInterval = setInterval(() => {
          if (!this.gameOver && !this.gameWon) { this.seconds++; }
        }, 1000);
      }
    }
    if (this.cells[r][c] === 9) {
      playClick();
      try { vibrator.vibrate(300); } catch (_) {}
      this.revealed[r][c] = true;
      for (let rr = 0; rr < this.gridSize; rr++) {
        for (let cc = 0; cc < this.gridSize; cc++) {
          if (this.cells[rr][cc] === 9) { this.revealed[rr][cc] = true; }
        }
      }
      this.gameOver = true;
      this.lastScore = this.seconds;
      if (this.seconds > this.bestScore) { this.bestScore = this.seconds; }
      this.syncFlat();
      setTimeout(() => { this.showOverlay = true; }, 300);
      return;
    }
    this.reveal(r, c);
    this.syncFlat();
    this.checkWin();
    playClick();
  }

  countFlags(): void {
    this.flagCount = 0;
    for (let rr = 0; rr < this.gridSize; rr++) {
      for (let cc = 0; cc < this.gridSize; cc++) {
        if (this.flagged[rr][cc]) { this.flagCount++; }
      }
    }
  }

  checkWin(): void {
    let totalSafe = 0;
    let totalRevealed = 0;
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.cells[r][c] !== 9) { totalSafe++; if (this.revealed[r][c]) { totalRevealed++; } }
      }
    }
    if (totalSafe === totalRevealed) {
      this.gameWon = true;
      this.lastScore = this.seconds;
      if (this.bestScore === 0 || this.seconds < this.bestScore) { this.bestScore = this.seconds; }
      this.syncFlat();
      setTimeout(() => { this.showOverlay = true; }, 300);
    }
  }

  cellText(index: number): string {
    if (!this.initialized) { return ''; }
    if (!this.flatRevealed[index]) {
      if (this.flatFlagged[index]) { return '🚩'; }
      return '';
    }
    let v = this.flatCells[index];
    if (v === 0) { return ''; }
    if (v === 9) { return '💣'; }
    return v.toString();
  }

  cellColor(index: number): string {
    if (!this.initialized) { return '#A0A0A0'; }
    if (!this.flatRevealed[index]) { return '#B0B0B0'; }
    let v = this.flatCells[index];
    if (v === 9) { return '#FF4444'; }
    if (v === 0) { return '#D8D8D8'; }
    return '#E8E8E8';
  }

  cellTextColor(index: number): string {
    if (!this.initialized) { return '#000000'; }
    if (!this.flatRevealed[index]) { return '#000000'; }
    let v = this.flatCells[index];
    if (v === 1) { return '#0000FF'; }
    if (v === 2) { return '#008000'; }
    if (v === 3) { return '#FF0000'; }
    if (v === 4) { return '#000080'; }
    if (v === 5) { return '#800000'; }
    if (v === 6) { return '#008080'; }
    if (v === 7) { return '#000000'; }
    if (v === 8) { return '#808080'; }
    return '#000000';
  }

  cellFontSize(index: number): number {
    if (!this.initialized) { return 16; }
    if (!this.flatRevealed[index]) { return 18; }
    let v = this.flatCells[index];
    if (v >= 10) { return 14; }
    if (v === 0) { return 0; }
    return 18;
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
                Text('扫雷').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('💣 ' + (this.mineCount - this.flagCount).toString()).fontSize(12).fontColor('#8B8B9E')
                Text('  ⏱ ' + this.seconds.toString() + 's').fontSize(12).fontColor('#8B8B9E')
              }
              .width('100%')

              Column() {
                Text((this.bestScore > 0 ? 'BEST  ' + this.bestScore.toString() + 's' : 'BEST  --') + ' | LAST  ' + this.lastScore.toString() + 's')
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
                ForEach(this.flatCells, (_value: number, index: number) => {
                  GridItem() {
                    Stack() {
                      Text(this.cellText(index))
                        .width('100%').height('100%')
                        .fontSize(this.cellFontSize(index))
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.cellTextColor(index))
                        .backgroundColor(this.cellColor(index))
                        .textAlign(TextAlign.Center)
                    }
                    .borderRadius(2).borderWidth(1).borderColor('#666666')
                  }
                  .onClick(() => { this.handleClick(index); })
                }, (index: number) => index.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(1).rowsGap(1)
              .width('100%').height('100%')

              if (this.showOverlay) {
                Column() {
                  Text(this.gameOver ? '游戏结束' : '你赢了！').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#776E65')
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 12 })
                  .onClick(() => { this.initGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#BAEEE4DA')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('100%')
            .constraintSize({ maxHeight: 380 })
            .aspectRatio(1)
            .alignSelf(ItemAlign.Center)
          }
          .width('100%')
          .height(450)
          .backgroundColor('#1A1A2E')
          .borderRadius(8)
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
      .onClick(() => { if (this.cursorRow > 0) { this.cursorRow--; playClick(); } })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { if (this.cursorRow < 8) { this.cursorRow++; playClick(); } })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { if (this.cursorCol > 0) { this.cursorCol--; playClick(); } })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { if (this.cursorCol < 8) { this.cursorCol++; playClick(); } })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.initGame(); })
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => {
        if (this.timerInterval > 0) { clearInterval(this.timerInterval); }
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { this.flagMode = !this.flagMode; })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => {
        let idx = this.cursorRow * this.gridSize + this.cursorCol;
        this.handleClick(idx);
      })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
