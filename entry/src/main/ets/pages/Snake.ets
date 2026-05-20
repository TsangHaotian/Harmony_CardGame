import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct Snake {
  @State snake: number[] = [0, 1, 2];
  @State food: number = 5;
  @State score: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State paused: boolean = false;
  @State flatCells: number[] = [];
  @StorageLink('BestSnake') bestScore: number = 0;
  @State lastScore: number = 0;

  private gridSize: number = 12;
  private dir: number = 1;
  private nextDirection: number = 1;
  private gameTimer: number = -1;
  private touchStartX: number = 0;
  private touchStartY: number = 0;

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.snake = [0, 1, 2];
    this.dir = 1;
    this.nextDirection = 1;
    this.score = 0;
    this.lastScore = 0;
    this.gameOver = false;
    this.showOverlay = false;
    this.paused = false;
    this.spawnFood();
    this.syncFlat();
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); }
    this.gameTimer = setInterval(() => { this.tick(); }, 250);
  }

  spawnFood(): void {
    let cells: number[] = [];
    for (let i = 0; i < this.gridSize * this.gridSize; i++) {
      let occupied = false;
      for (let j = 0; j < this.snake.length; j++) { if (this.snake[j] === i) { occupied = true; break; } }
      if (!occupied) { cells.push(i); }
    }
    if (cells.length > 0) { this.food = cells[Math.floor(Math.random() * cells.length)]; }
  }

  tick(): void {
    if (this.gameOver || this.showOverlay || this.paused) { return; }
    this.dir = this.nextDirection;
    let head = this.snake[this.snake.length - 1];
    let row = Math.floor(head / this.gridSize);
    let col = head % this.gridSize;
    if (this.dir === 0) { row--; }
    if (this.dir === 1) { col++; }
    if (this.dir === 2) { row++; }
    if (this.dir === 3) { col--; }
    if (row < 0) { row = this.gridSize - 1; }
    if (row >= this.gridSize) { row = 0; }
    if (col < 0) { col = this.gridSize - 1; }
    if (col >= this.gridSize) { col = 0; }
    let newHead = row * this.gridSize + col;
    for (let i = 0; i < this.snake.length - 1; i++) {
      if (this.snake[i] === newHead) { this.endGame(); return; }
    }
    let ate = newHead === this.food;
    this.snake.push(newHead);
    if (!ate) { this.snake.shift(); }
    else { this.score++; vibrate(15); this.spawnFood(); }
    this.snake = [...this.snake];
    this.syncFlat();
  }

  endGame(): void {
    this.gameOver = true;
    vibrate(300);
    this.lastScore = this.score;
    if (this.score > this.bestScore) { this.bestScore = this.score; }
    setTimeout(() => { this.showOverlay = true; }, 200);
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
  }

  syncFlat(): void {
    let cells: number[] = [];
    for (let i = 0; i < this.gridSize * this.gridSize; i++) {
      let isSnake = 0;
      for (let j = 0; j < this.snake.length; j++) {
        if (this.snake[j] === i) { isSnake = j === this.snake.length - 1 ? 2 : 1; break; }
      }
      if (i === this.food) { cells.push(3); }
      else if (isSnake === 2) { cells.push(2); }
      else if (isSnake === 1) { cells.push(1); }
      else { cells.push(0); }
    }
    this.flatCells = cells;
  }

  changeDirection(d: number): void {
    if ((this.dir === 0 && d === 2) || (this.dir === 2 && d === 0) ||
        (this.dir === 1 && d === 3) || (this.dir === 3 && d === 1)) { return; }
    this.nextDirection = d;
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            // Scoreboard area (top)
            Column() {
              Row() {
                Text('贪吃蛇').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('长度: ' + (this.score + 3).toString()).fontSize(12).fontColor('#8B8B9E')
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
                ForEach(this.flatCells, (v: number, index: number) => {
                  GridItem() {
                    Stack() {
                      Text(v === 3 ? '🍎' : '').fontSize(16).textAlign(TextAlign.Center).width('100%').height('100%')
                    }
                    .width('100%').height('100%')
                    .borderRadius(3)
                    .backgroundColor(v === 0 ? '#2A2A3E' : v === 1 ? '#8F7A66' : v === 2 ? '#6B5B4F' : '#FFFFFF')
                  }
                }, (index: number) => index.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(2).rowsGap(2)
              .width('100%').height('100%')
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down && event.touches.length > 0) {
                  this.touchStartX = event.touches[0].x;
                  this.touchStartY = event.touches[0].y;
                } else if (event.type === TouchType.Up && event.touches.length > 0) {
                  let dx = event.touches[0].x - this.touchStartX;
                  let dy = event.touches[0].y - this.touchStartY;
                  if (Math.abs(dx) > 20 || Math.abs(dy) > 20) {
                    if (Math.abs(dx) > Math.abs(dy)) { this.changeDirection(dx > 0 ? 1 : 3); }
                    else { this.changeDirection(dy > 0 ? 2 : 0); }
                  }
                }
              })

              if (this.gameOver || this.showOverlay) {
                Column() {
                  Text('游戏结束').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#776E65')
                  Text('长度: ' + (this.score + 3).toString()).fontSize(18).fontColor('#CC4444').margin({ top: 6 })
                  Button() { Text('再来一局').fontSize(14).fontColor('#F9F6F2') }
                  .backgroundColor('#8F7A66').borderRadius(6).margin({ top: 12 })
                  .onClick(() => { this.startGame(); })
                }
                .width('100%').height('100%')
                .backgroundColor('#BAEEE4DA')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('100%')
            .aspectRatio(1)
            .alignSelf(ItemAlign.Center)
          }
          .width('100%')
          .height(450)
          .backgroundColor('#1A1A2E')
          .borderRadius(8)
          .padding({ top: 10, bottom: 8, left: 12, right: 12 })
        }
        .backgroundColor('#444444').borderRadius(12).padding(8)
        .margin({ top: 20, left: 16, right: 16 })

        Row() { this.StartSelectLayout() }
        .padding({ top: 14, bottom: 4 })

        Row() {
          this.DPadLayout()
          Blank().layoutWeight(1)
          this.ActionButtonLayout()
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 16, right: 24, bottom: 4 })

        Text('HARMONY GB').fontSize(11).fontColor('#888888').margin({ bottom: 6 })
      }
      .width('92%').layoutWeight(1).backgroundColor('#D4D0C8').borderRadius(24)
    }
    .width('100%').height('100%').backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center).padding({ top: 40, bottom: 15 })
  }

  @Builder DPadLayout() {
    Stack() {
      Button() { Image($r('app.media.icon_up')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: -42 })
      .onClick(() => { this.changeDirection(0); vibrate(8); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.changeDirection(2); vibrate(8); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.changeDirection(3); vibrate(8); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.changeDirection(1); vibrate(8); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.paused = !this.paused; })
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
      .onClick(() => { this.paused = !this.paused; vibrate(10); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => {
        if (!this.gameOver && !this.showOverlay && this.gameTimer > 0) {
          clearInterval(this.gameTimer);
          this.gameTimer = setInterval(() => { this.tick(); }, 80);
          vibrate(15);
        }
      })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
