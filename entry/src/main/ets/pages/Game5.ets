import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct Game5 {
  @State grid: number[] = [];
  @State ballX: number = 6;
  @State ballY: number = 18;
  @State paddleX: number = 4;
  @State score: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State bestScore: number = AppStorage.get<number>('BestFlappy') ?? 0;
  @State lastScore: number = 0;

  private cols: number = 16;
  private rows: number = 28;
  private paddleW: number = 5;
  private bDirX: number = 1;
  private bDirY: number = -1;
  private gameTimer: number = -1;
  private speed: number = 180;
  private bricks: number[] = [];

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.score = 0;
    this.gameOver = false;
    this.showOverlay = false;
    this.lastScore = 0;
    this.ballX = 8;
    this.ballY = 24;
    this.paddleX = 5;
    this.bDirX = 1;
    this.bDirY = -1;
    this.buildGrid();
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    this.gameTimer = setInterval(() => { this.tick(); }, this.speed);
  }

  buildGrid(): void {
    this.bricks = new Array(5 * this.cols).fill(0);
    for (let r = 0; r < 5; r++) {
      for (let c = 0; c < this.cols; c++) {
        this.bricks[r * this.cols + c] = 10 + Math.floor(c / 4);
      }
    }
    this.renderGrid();
  }

  tick(): void {
    if (this.gameOver || this.showOverlay) return;

    let nx = this.ballX + this.bDirX;
    let ny = this.ballY + this.bDirY;

    if (nx < 0 || nx >= this.cols) { this.bDirX *= -1; nx = this.ballX + this.bDirX; }
    if (ny < 0) { this.bDirY *= -1; ny = this.ballY + this.bDirY; }

    if (ny >= this.rows - 1) {
      if (nx >= this.paddleX && nx < this.paddleX + this.paddleW) {
        this.bDirY *= -1;
        this.bDirX = Math.max(-2, Math.min(2, nx - this.paddleX - 1));
        if (this.bDirX === 0) this.bDirX = 1;
        ny = this.ballY + this.bDirY;
        vibrate(5);
      } else {
        this.endGame(); return;
      }
    }

    if (ny >= 0 && ny < 5 && nx >= 0 && nx < this.cols) {
      let idx = ny * this.cols + nx;
      if (this.bricks[idx] >= 10) {
        this.bricks[idx] = 0;
        this.score++;
        this.bDirY *= -1;
        ny = this.ballY + this.bDirY;
        vibrate(8);
        let anyBrick = false;
        for (let i = 0; i < this.bricks.length; i++) { if (this.bricks[i] >= 10) { anyBrick = true; break; } }
        if (!anyBrick) {
          for (let r = 0; r < 5; r++) { for (let c = 0; c < this.cols; c++) { this.bricks[r * this.cols + c] = 10 + Math.floor(c / 4); } }
          this.score += 5;
          vibrate(15);
        }
      }
    }

    this.ballX = nx;
    this.ballY = ny;
    this.renderGrid();
  }

  moveLeft(): void {
    if (this.gameOver || this.showOverlay) return;
    if (this.paddleX > 0) { this.paddleX--; vibrate(3); }
  }

  moveRight(): void {
    if (this.gameOver || this.showOverlay) return;
    if (this.paddleX + this.paddleW < this.cols) { this.paddleX++; vibrate(3); }
  }

  renderGrid(): void {
    let g: number[] = new Array(this.rows * this.cols).fill(0);
    // Bricks
    for (let i = 0; i < this.bricks.length; i++) {
      if (this.bricks[i] >= 10) {
        let r = Math.floor(i / this.cols);
        let c = i % this.cols;
        g[r * this.cols + c] = this.bricks[i];
      }
    }
    // Ball
    if (this.ballY >= 0 && this.ballY < this.rows && this.ballX >= 0 && this.ballX < this.cols) {
      g[this.ballY * this.cols + this.ballX] = 1;
    }
    // Paddle
    for (let c = this.paddleX; c < this.paddleX + this.paddleW; c++) {
      if (c >= 0 && c < this.cols) { g[(this.rows - 1) * this.cols + c] = 2; }
    }
    this.grid = g;
  }

  endGame(): void {
    this.gameOver = true;
    vibrate(300);
    this.lastScore = this.score;
    if (this.score > this.bestScore) { this.bestScore = this.score; AppStorage.set<number>('BestFlappy', this.bestScore); }
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    setTimeout(() => { this.showOverlay = true; }, 300);
  }

  cellBg(v: number): string {
    if (v === 1) return '#FFDD44';
    if (v === 2) return '#4488CC';
    if (v === 10) return '#E74C3C';
    if (v === 11) return '#E67E22';
    if (v === 12) return '#2ECC71';
    if (v === 13) return '#3498DB';
    return '#1A1A2E';
  }

  build() {
    Column() {
      Column() {
        Scroll() {
        Column() {
        Column() {
          Column() {
            Row() {
              Text('打砖块').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
              Blank()
              Text('得分: ').fontSize(11).fontColor('#8B8B9E')
              Text(this.score.toString()).fontSize(11).fontColor('#FFD700').fontWeight(FontWeight.Bold)
              Text('  BEST ').fontSize(10).fontColor('#8B8B9E').margin({ left: 4 })
              Text(this.bestScore.toString()).fontSize(10).fontColor('#FFD700').fontWeight(FontWeight.Bold)
              Text('  LAST ').fontSize(10).fontColor('#8B8B9E').margin({ left: 2 })
              Text(this.lastScore.toString()).fontSize(10).fontColor('#888888')
            }
            .width('100%')

            Stack() {
              Grid() {
                ForEach(this.grid, (v: number, i: number) => {
                  GridItem() {
                    Stack() {
                      if (v === 1) {
                        Circle().width('70%').height('70%').fill('#FFFFFF')
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cellBg(v))
                    .borderRadius(v === 2 ? 4 : 0)
                  }
                }, (i: number) => i.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(1).rowsGap(1)
              .width('85%').constraintSize({ maxHeight: 380 }).aspectRatio(16 / 28).alignSelf(ItemAlign.Center)

              if (this.showOverlay) {
                Column() {
                  Text('游戏结束').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
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
            .width('85%').constraintSize({ maxHeight: 380 }).aspectRatio(16 / 28).alignSelf(ItemAlign.Center)
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
      .onClick(() => { vibrate(8); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { vibrate(8); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveLeft(); vibrate(8); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveRight(); vibrate(8); })
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
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { this.moveLeft(); vibrate(10); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { this.moveRight(); vibrate(10); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
