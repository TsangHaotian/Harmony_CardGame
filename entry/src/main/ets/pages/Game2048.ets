import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct Game2048 {
  @State flatTiles: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State score: number = 0;
  @State bestScore: number = 0;
  @State gameOver: boolean = false;
  @State hasWon: boolean = false;
  @State showOverlay: boolean = false;
  @State newTileIndex: number = -1;
  @State scorePop: boolean = false;

  private gridSize: number = 4;
  private tiles: number[][] = [
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0]
  ];
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private readonly MIN_SWIPE_DISTANCE: number = 30;

  aboutToAppear(): void {
    this.initGame();
  }

  initGame(): void {
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        this.tiles[r][c] = 0;
      }
    }
    this.score = 0;
    this.gameOver = false;
    this.hasWon = false;
    this.showOverlay = false;
    this.newTileIndex = -1;
    this.addRandomTile();
    this.addRandomTile();
    this.syncFlatTiles();
  }

  syncFlatTiles(): void {
    let result: number[] = [];
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        result.push(this.tiles[r][c]);
      }
    }
    this.flatTiles = result;
  }

  addRandomTile(): void {
    let emptyCells: number[][] = [];
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.tiles[r][c] === 0) {
          emptyCells.push([r, c]);
        }
      }
    }
    if (emptyCells.length === 0) {
      return;
    }
    const idx = Math.floor(Math.random() * emptyCells.length);
    const cell = emptyCells[idx];
    this.tiles[cell[0]][cell[1]] = Math.random() < 0.9 ? 2 : 4;
    this.newTileIndex = cell[0] * this.gridSize + cell[1];
  }

  slideLine(line: number[]): number[] {
    let compressed: number[] = [];
    for (let i = 0; i < line.length; i++) {
      if (line[i] !== 0) {
        compressed.push(line[i]);
      }
    }
    let merged: number[] = [];
    let i = 0;
    while (i < compressed.length) {
      if (i + 1 < compressed.length && compressed[i] === compressed[i + 1]) {
        const mergedValue = compressed[i] * 2;
        merged.push(mergedValue);
        this.score += mergedValue;
        i += 2;
      } else {
        merged.push(compressed[i]);
        i++;
      }
    }
    while (merged.length < this.gridSize) {
      merged.push(0);
    }
    return merged;
  }

  linesEqual(a: number[], b: number[]): boolean {
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) {
        return false;
      }
    }
    return true;
  }

  moveLeft(): void {
    for (let r = 0; r < this.gridSize; r++) {
      const oldRow = [...this.tiles[r]];
      const newRow = this.slideLine(oldRow);
      if (!this.linesEqual(oldRow, newRow)) {
        this.tiles[r] = newRow;
      }
    }
  }

  moveRight(): void {
    for (let r = 0; r < this.gridSize; r++) {
      const oldRow = [...this.tiles[r]];
      const reversed = oldRow.reverse();
      const merged = this.slideLine(reversed);
      const newRow = merged.reverse();
      if (!this.linesEqual(oldRow, newRow)) {
        this.tiles[r] = newRow;
      }
    }
  }

  moveUp(): void {
    for (let c = 0; c < this.gridSize; c++) {
      let col: number[] = [];
      for (let r = 0; r < this.gridSize; r++) {
        col.push(this.tiles[r][c]);
      }
      const newCol = this.slideLine(col);
      if (!this.linesEqual(col, newCol)) {
        for (let r = 0; r < this.gridSize; r++) {
          this.tiles[r][c] = newCol[r];
        }
      }
    }
  }

  moveDown(): void {
    for (let c = 0; c < this.gridSize; c++) {
      let col: number[] = [];
      for (let r = this.gridSize - 1; r >= 0; r--) {
        col.push(this.tiles[r][c]);
      }
      const merged = this.slideLine(col);
      const newCol = merged.reverse();
      let origCol: number[] = [];
      for (let r = 0; r < this.gridSize; r++) {
        origCol.push(this.tiles[r][c]);
      }
      if (!this.linesEqual(origCol, newCol)) {
        for (let r = 0; r < this.gridSize; r++) {
          this.tiles[r][c] = newCol[r];
        }
      }
    }
  }

  tryMove(direction: string): void {
    if (this.gameOver || this.hasWon) {
      return;
    }

    const before = this.tiles.map(row => [...row]);

    if (direction === 'left') {
      this.moveLeft();
    } else if (direction === 'right') {
      this.moveRight();
    } else if (direction === 'up') {
      this.moveUp();
    } else if (direction === 'down') {
      this.moveDown();
    }

    let changed = false;
    for (let r = 0; r < this.gridSize && !changed; r++) {
      for (let c = 0; c < this.gridSize && !changed; c++) {
        if (before[r][c] !== this.tiles[r][c]) {
          changed = true;
        }
      }
    }

    if (changed) {
      vibrate(15);
      this.newTileIndex = -1;
      this.addRandomTile();
      this.syncFlatTiles();

      if (!this.hasWon && this.hasTileValue(2048)) {
        this.hasWon = true;
        vibrate(200);
        setTimeout(() => {
          this.showOverlay = true;
        }, 200);
      }
      if (this.isGameOver()) {
        vibrate(300);
        setTimeout(() => {
          this.showOverlay = true;
        }, 200);
      }
      if (this.score > this.bestScore) {
        this.bestScore = this.score;
      }
    }
  }

  hasTileValue(value: number): boolean {
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.tiles[r][c] === value) {
          return true;
        }
      }
    }
    return false;
  }

  isGameOver(): boolean {
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        if (this.tiles[r][c] === 0) {
          return false;
        }
      }
    }
    for (let r = 0; r < this.gridSize; r++) {
      for (let c = 0; c < this.gridSize; c++) {
        const v = this.tiles[r][c];
        if (c + 1 < this.gridSize && this.tiles[r][c + 1] === v) {
          return false;
        }
        if (r + 1 < this.gridSize && this.tiles[r + 1][c] === v) {
          return false;
        }
      }
    }
    return true;
  }

  getTileColor(value: number): string {
    if (value === 0) { return '#CDC1B4'; }
    if (value === 2) { return '#EEE4DA'; }
    if (value === 4) { return '#EDE0C8'; }
    if (value === 8) { return '#F2B179'; }
    if (value === 16) { return '#F59563'; }
    if (value === 32) { return '#F67C5F'; }
    if (value === 64) { return '#F65E3B'; }
    if (value === 128) { return '#EDCF72'; }
    if (value === 256) { return '#EDCC61'; }
    if (value === 512) { return '#EDC850'; }
    if (value === 1024) { return '#EDC53F'; }
    if (value === 2048) { return '#EDC22E'; }
    return '#3C3A32';
  }

  getTextColor(value: number): string {
    if (value <= 4) {
      return '#776E65';
    }
    return '#F9F6F2';
  }

  getTileFontSize(value: number): number {
    if (value < 100) {
      return 36;
    }
    if (value < 1000) {
      return 28;
    }
    if (value < 10000) {
      return 22;
    }
    return 18;
  }

  handleTouchStart(event: TouchEvent): void {
    if (event.touches.length > 0) {
      this.touchStartX = event.touches[0].x;
      this.touchStartY = event.touches[0].y;
    }
  }

  handleTouchEnd(event: TouchEvent): void {
    if (event.touches.length > 0) {
      const dx = event.touches[0].x - this.touchStartX;
      const dy = event.touches[0].y - this.touchStartY;
      const absX = Math.abs(dx);
      const absY = Math.abs(dy);

      if (absX < this.MIN_SWIPE_DISTANCE && absY < this.MIN_SWIPE_DISTANCE) {
        return;
      }

      if (absX > absY) {
        this.tryMove(dx > 0 ? 'right' : 'left');
      } else {
        this.tryMove(dy > 0 ? 'down' : 'up');
      }
    }
  }

  isNewTile(index: number): boolean {
    return index === this.newTileIndex;
  }

  build() {
    Column() {
      // top spacer
      Blank()

      // Top bar
      Row() {
        Button() {
          Text('← 返回')
            .fontSize(16)
            .fontColor('#776E65')
        }
        .backgroundColor('transparent')
        .onClick(() => {
          try {
            this.getUIContext().getRouter().back();
          } catch (_) {}
        })

        Text('2048')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')

        Button() {
          Text('新局')
            .fontSize(16)
            .fontColor('#F9F6F2')
        }
        .backgroundColor('#8F7A66')
        .borderRadius(8)
        .width(72)
        .height(40)
        .onClick(() => {
          this.initGame();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // Score row
      Row() {
        Stack() {
          Column() {
            Text('SCORE')
              .fontSize(11)
              .fontColor('#EEE4DA')
            Text(this.score.toString())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width(90)
        .height(56)
        .backgroundColor('#BBADA0')
        .borderRadius(6)

        Stack() {
          Column() {
            Text('BEST')
              .fontSize(11)
              .fontColor('#EEE4DA')
            Text(this.bestScore.toString())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width(90)
        .height(56)
        .backgroundColor('#BBADA0')
        .borderRadius(6)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 16 })

      // Game grid
      Stack() {
        Grid() {
          ForEach(this.flatTiles, (cellValue: number, index: number) => {
            GridItem() {
              Stack() {
                Text(cellValue === 0 ? '' : cellValue.toString())
                  .width('100%')
                  .height('100%')
                  .fontSize(this.getTileFontSize(cellValue))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getTextColor(cellValue))
                  .backgroundColor(this.getTileColor(cellValue))
                  .borderRadius(6)
                  .textAlign(TextAlign.Center)
              }
            }
          }, (index: number) => index.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width(320)
        .height(320)
        .backgroundColor('#BBADA0')
        .borderRadius(8)
        .padding(8)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.handleTouchStart(event);
          } else if (event.type === TouchType.Up) {
            this.handleTouchEnd(event);
          }
        })

        // overlay
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
          .width(320)
          .height(320)
          .backgroundColor('#BAEEE4DA')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .borderRadius(8)
          .transition(TransitionEffect.opacity(0))
        }
      }
      .width(320)
      .height(320)

      Text('滑动屏幕移动方块')
        .fontSize(14)
        .fontColor('#776E65')
        .margin({ top: 20 })
        .opacity(0.6)

      // bottom spacer
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
