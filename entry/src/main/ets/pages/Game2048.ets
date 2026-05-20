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
  @StorageLink('Best2048') bestScore: number = 0;
  @State gameOver: boolean = false;
  @State hasWon: boolean = false;
  @State showOverlay: boolean = false;
  @State newTileIndex: number = -1;
  @State scorePop: boolean = false;
  @State lastScore: number = 0;
  @State prevTiles: number[] = [];
  @State prevScore: number = 0;

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
    this.lastScore = 0;
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
      this.prevTiles = [...this.flatTiles];
      this.prevScore = this.score;
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
        this.lastScore = this.score;
        if (this.score > this.bestScore) { this.bestScore = this.score; }
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
      // Console body
      Column() {
        Scroll() {
        Column() {
        // Screen bezel
        Column() {
          // Screen — game content (DO NOT CHANGE SIZE)
          Column() {
            // Scoreboard area (top)
            Column() {
              Row() {
                Text('2048')
                  .fontSize(16)
                  .fontColor('#FF6B35')
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text('SCORE: ' + this.score.toString())
                  .fontSize(12)
                  .fontColor('#8B8B9E')
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
              .columnsGap(4)
              .rowsGap(4)
              .width('100%')
              .height('100%')
              .backgroundColor('#BBADA0')
              .borderRadius(8)
              .padding(4)

              // overlay
              if (this.showOverlay) {
                Column() {
                  Text(this.gameOver ? '游戏结束' : '你赢了！')
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#776E65')
                  Button() {
                    Text('再来一局')
                      .fontSize(14)
                      .fontColor('#F9F6F2')
                  }
                  .backgroundColor('#8F7A66')
                  .borderRadius(6)
                  .margin({ top: 12 })
                  .onClick(() => {
                    this.initGame();
                  })
                }
                .width('100%')
                .height('100%')
                .backgroundColor('#BAEEE4DA')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
                .borderRadius(8)
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
        .backgroundColor('#444444')
        .borderRadius(12)
        .padding(8)
        .margin({ top: 20, left: 16, right: 16 })

        // Start / Select
        Row() {
          this.StartSelectLayout()
        }
        .padding({ top: 14, bottom: 4 })

        // D-Pad left, A/B right
        Row() {
          this.DPadLayout()
          Blank().layoutWeight(1)
          this.ActionButtonLayout()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 24, bottom: 4 })

        Text('HARMONY GB')
          .fontSize(11)
          .fontColor('#888888')
          .margin({ bottom: 6 })
      }
      .width('92%')
      .layoutWeight(1)
      .constraintSize({ maxWidth: 540 })
      .backgroundColor('#D4D0C8')
      .borderRadius(24)
    }
    }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 40, bottom: 15 })
  }

  @Builder DPadLayout() {
    Stack() {
      Button() {
        Image($r('app.media.icon_up')).width(60).height(60)
      }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0)
      .offset({ y: -42 })
      .onClick(() => { this.tryMove('up'); vibrate(8); })
      Button() {
        Image($r('app.media.icon_down')).width(60).height(60)
      }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0)
      .offset({ y: 42 })
      .onClick(() => { this.tryMove('down'); vibrate(8); })
      Button() {
        Image($r('app.media.icon_left')).width(60).height(60)
      }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0)
      .offset({ x: -42 })
      .onClick(() => { this.tryMove('left'); vibrate(8); })
      Button() {
        Image($r('app.media.icon_right')).width(60).height(60)
      }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0)
      .offset({ x: 42 })
      .onClick(() => { this.tryMove('right'); vibrate(8); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() {
        Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.initGame(); })

      Button() {
        Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14)
      .margin({ left: 16 })
      .onClick(() => {
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() {
        Circle().width(56).height(56).fill('#4488CC')
        Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .onClick(() => {
        if (this.prevTiles.length > 0 && !this.showOverlay) {
          this.flatTiles = this.prevTiles;
          this.score = this.prevScore;
          this.prevTiles = [];
          vibrate(10);
        }
      })

      Stack() {
        Circle().width(64).height(64).fill('#CC4444')
        Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .margin({ left: 12 })
      .onClick(() => { this.initGame(); vibrate(15); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
