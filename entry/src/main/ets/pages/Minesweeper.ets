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
    this.showOverlay = false;
    this.flagCount = 0;
    this.seconds = 0;
    this.initialized = true;
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
      if (this.cells[r][c] === 9) {
        continue;
      }
      if (Math.abs(r - safeR) <= 1 && Math.abs(c - safeC) <= 1) {
        continue;
      }
      this.cells[r][c] = 9;
      placed++;
    }
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.cells[r][c] === 9) {
          continue;
        }
        let count = 0;
        for (let d = 0; d < this.DIRS.length; d++) {
          let nr = r + this.DIRS[d][0];
          let nc = c + this.DIRS[d][1];
          if (nr >= 0 && nr < this.gridSize && nc >= 0 && nc < this.gridSize && this.cells[nr][nc] === 9) {
            count++;
          }
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
    if (r < 0 || r >= this.gridSize || c < 0 || c >= this.gridSize) {
      return;
    }
    if (this.revealed[r][c] || this.flagged[r][c]) {
      return;
    }
    this.revealed[r][c] = true;
    if (this.cells[r][c] === 0) {
      for (let d = 0; d < this.DIRS.length; d++) {
        this.reveal(r + this.DIRS[d][0], c + this.DIRS[d][1]);
      }
    }
  }

  handleClick(index: number): void {
    if (this.gameOver || this.gameWon || this.showOverlay) {
      return;
    }
    let r = Math.floor(index / this.gridSize);
    let c = index % this.gridSize;
    if (this.revealed[r][c]) {
      return;
    }
    if (this.flagMode) {
      this.flagged[r][c] = !this.flagged[r][c];
      this.countFlags();
      this.syncFlat();
      return;
    }
    if (this.flagged[r][c]) {
      return;
    }
    if (this.firstClick) {
      this.placeMines(r, c);
      this.firstClick = false;
      if (this.timerInterval < 0) {
        this.timerInterval = setInterval(() => {
          if (!this.gameOver && !this.gameWon) {
            this.seconds++;
          }
        }, 1000);
      }
    }
    if (this.cells[r][c] === 9) {
      this.revealed[r][c] = true;
      for (let rr = 0; rr < this.gridSize; rr++) {
        for (let cc = 0; cc < this.gridSize; cc++) {
          if (this.cells[rr][cc] === 9) {
            this.revealed[rr][cc] = true;
          }
        }
      }
      this.gameOver = true;
      this.syncFlat();
      setTimeout(() => { this.showOverlay = true; }, 300);
      return;
    }
    this.reveal(r, c);
    this.syncFlat();
    this.checkWin();
  }

  countFlags(): void {
    this.flagCount = 0;
    for (let rr = 0; rr < this.gridSize; rr++) {
      for (let cc = 0; cc < this.gridSize; cc++) {
        if (this.flagged[rr][cc]) {
          this.flagCount++;
        }
      }
    }
  }

  checkWin(): void {
    let totalSafe = 0;
    let totalRevealed = 0;
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.cells[r][c] !== 9) {
          totalSafe++;
          if (this.revealed[r][c]) {
            totalRevealed++;
          }
        }
      }
    }
    if (totalSafe === totalRevealed) {
      this.gameWon = true;
      this.syncFlat();
      setTimeout(() => { this.showOverlay = true; }, 300);
    }
  }

  cellText(index: number): string {
    if (!this.initialized) { return ''; }
    if (!this.flatRevealed[index]) {
      if (this.flatFlagged[index]) {
        return '🚩';
      }
      return '';
    }
    let v = this.flatCells[index];
    if (v === 0) { return ''; }
    if (v === 9) { return '💣'; }
    return v.toString();
  }

  cellColor(index: number): string {
    if (!this.initialized) { return '#A0A0A0'; }
    if (!this.flatRevealed[index]) {
      return '#B0B0B0';
    }
    let v = this.flatCells[index];
    if (v === 9) { return '#FF4444'; }
    if (v === 0) { return '#D8D8D8'; }
    return '#E8E8E8';
  }

  cellTextColor(index: number): string {
    if (!this.initialized) { return '#000000'; }
    if (!this.flatRevealed[index]) {
      return '#000000';
    }
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
      Blank()

      Row() {
        Button() {
          Text('← 返回')
            .fontSize(16)
            .fontColor('#776E65')
        }
        .backgroundColor('transparent')
        .onClick(() => {
          try {
            if (this.timerInterval > 0) {
              clearInterval(this.timerInterval);
            }
            this.getUIContext().getRouter().back();
          } catch (_) {}
        })

        Text('💣 ' + (this.mineCount - this.flagCount).toString())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Button() {
          Text(this.flagMode ? '⛏️' : '🚩')
            .fontSize(20)
        }
        .backgroundColor(this.flagMode ? '#FFD700' : 'transparent')
        .borderRadius(6)
        .width(40)
        .height(40)
        .onClick(() => {
          this.flagMode = !this.flagMode;
        })

        Button() {
          Text('😊')
            .fontSize(24)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          this.initGame();
        })

        Text(this.seconds.toString() + 's')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 12 })

      Stack() {
        Grid() {
          ForEach(this.flatCells, (_value: number, index: number) => {
            GridItem() {
              Stack() {
                Text(this.cellText(index))
                  .width('100%')
                  .height('100%')
                  .fontSize(this.cellFontSize(index))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.cellTextColor(index))
                  .backgroundColor(this.cellColor(index))
                  .textAlign(TextAlign.Center)
              }
              .borderRadius(3)
              .borderWidth(1)
              .borderColor('#999999')
            }
            .onClick(() => {
              this.handleClick(index);
            })
          }, (index: number) => index.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(1)
        .rowsGap(1)
        .width(306)
        .height(306)

        if (this.showOverlay) {
          Column() {
            Text(this.gameOver ? '游戏结束' : '你赢了！')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#776E65')
            Button() {
              Text('再来一局')
                .fontSize(16)
                .fontColor('#F9F6F2')
            }
            .backgroundColor('#8F7A66')
            .borderRadius(8)
            .margin({ top: 16 })
            .onClick(() => {
              this.initGame();
            })
          }
          .width(306)
          .height(306)
          .backgroundColor('#BAEEE4DA')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .borderRadius(8)
          .transition(TransitionEffect.opacity(0))
        }
      }
      .width(306)
      .height(306)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
