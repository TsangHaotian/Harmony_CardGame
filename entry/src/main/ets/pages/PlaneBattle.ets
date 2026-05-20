import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct PlaneBattle {
  @State playerCol: number = 3;
  @State enemies: number[][] = [];
  @State bullets: number[][] = [];
  @State score: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State grid: number[] = [];
  @StorageLink('BestPlane') bestScore: number = 0;
  @State lastScore: number = 0;
  private rows: number = 14;
  private cols: number = 7;
  private gameTimer: number = -1;
  private spawnTimer: number = -1;
  private speed: number = 350;
  private canShoot: boolean = true;

  aboutToAppear(): void {
    this.startGame();
  }

  startGame(): void {
    this.score = 0;
    this.lastScore = 0;
    this.playerCol = 3;
    this.gameOver = false;
    this.showOverlay = false;
    this.enemies = [];
    this.bullets = [];
    this.speed = 350;
    this.canShoot = true;
    this.buildGrid();
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); this.spawnTimer = -1; }
    this.gameTimer = setInterval(() => { this.tick(); }, this.speed);
    this.spawnTimer = setInterval(() => { this.spawnEnemy(); }, 1500);
  }

  buildGrid(): void {
    let g: number[] = [];
    for (let i = 0; i < this.rows * this.cols; i++) { g.push(0); }
    this.grid = g;
  }

  spawnEnemy(): void {
    if (this.gameOver || this.showOverlay) { return; }
    let count = Math.random() < 0.4 ? 2 : 1;
    for (let i = 0; i < count; i++) {
      let col = Math.floor(Math.random() * this.cols);
      this.enemies.push([0, col]);
    }
  }

  tick(): void {
    if (this.gameOver || this.showOverlay) { return; }
    // Move enemies down
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      this.enemies[i][0]++;
      if (this.enemies[i][0] >= this.rows) {
        this.enemies.splice(i, 1);
      }
    }
    // Move bullets up & check collision along path
    for (let i = this.bullets.length - 1; i >= 0; i--) {
      let prevRow = this.bullets[i][0];
      this.bullets[i][0]--;
      let newRow = this.bullets[i][0];
      if (newRow < 0) {
        this.bullets.splice(i, 1);
        continue;
      }
      // Check enemy in the path (prevRow or newRow)
      for (let ei = this.enemies.length - 1; ei >= 0; ei--) {
        if (this.bullets[i][1] === this.enemies[ei][1] &&
            (this.enemies[ei][0] === prevRow || this.enemies[ei][0] === newRow)) {
          this.bullets.splice(i, 1);
          this.enemies.splice(ei, 1);
          this.score += 10;
          vibrate(15);
          break;
        }
      }
    }
    // Enemy-player collision
    let playerRow = this.rows - 2;
    for (let i = 0; i < this.enemies.length; i++) {
      if (this.enemies[i][0] === playerRow && this.enemies[i][1] === this.playerCol) {
        this.endGame();
        return;
      }
    }
    // Enemy passed bottom — remove it, no penalty
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      if (this.enemies[i][0] >= this.rows - 1) {
        this.enemies.splice(i, 1);
      }
    }
    this.renderGrid();
  }

  renderGrid(): void {
    let g: number[] = new Array(this.rows * this.cols).fill(0);
    // Enemies
    for (let i = 0; i < this.enemies.length; i++) {
      let row = this.enemies[i][0];
      let col = this.enemies[i][1];
      if (row >= 0 && row < this.rows) { g[row * this.cols + col] = 2; }
    }
    // Bullets
    for (let i = 0; i < this.bullets.length; i++) {
      let row = this.bullets[i][0];
      let col = this.bullets[i][1];
      if (row >= 0 && row < this.rows && g[row * this.cols + col] === 0) {
        g[row * this.cols + col] = 3;
      }
    }
    // Player
    let playerRow = this.rows - 2;
    g[playerRow * this.cols + this.playerCol] = 1;
    this.grid = g;
  }

  moveLeft(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol > 0) { this.playerCol--; this.renderGrid(); vibrate(5); }
  }

  moveRight(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (this.playerCol < this.cols - 1) { this.playerCol++; this.renderGrid(); vibrate(5); }
  }

  shoot(): void {
    if (this.gameOver || this.showOverlay) { return; }
    if (!this.canShoot) { return; }
    this.canShoot = false;
    let bulletRow = this.rows - 3;
    this.bullets.push([bulletRow, this.playerCol]);
    this.renderGrid();
    vibrate(8);
    setTimeout(() => { this.canShoot = true; }, 200);
  }

  endGame(): void {
    this.gameOver = true;
    vibrate(300);
    this.lastScore = this.score;
    if (this.score > this.bestScore) { this.bestScore = this.score; }
    if (this.gameTimer > 0) { clearInterval(this.gameTimer); this.gameTimer = -1; }
    if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); this.spawnTimer = -1; }
    setTimeout(() => { this.showOverlay = true; }, 300);
  }

  cellBg(v: number): string {
    if (v === 1) { return '#44DD44'; }    // player (green)
    if (v === 2) { return '#DD4444'; }    // enemy (red)
    if (v === 3) { return '#FFDD44'; }    // bullet (yellow)
    return '#1A1A2E';                     // empty (dark)
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            // Scoreboard area (top)
            Column() {
              Row() {
                Text('飞机大战').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                Blank()
                Text('得分: ' + this.score.toString()).fontSize(12).fontColor('#8B8B9E')
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
                ForEach(this.grid, (v: number, index: number) => {
                  GridItem() {
                    Stack() {
                      if (v === 1) {
                        Row() {
                          Text('▲').fontSize(11).fontColor('#003300').fontWeight(FontWeight.Bold)
                        }
                        .width('100%').height('100%')
                        .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cellBg(v))
                    .borderRadius(v === 2 ? 6 : v === 1 ? 2 : 0)
                  }
                }, (index: number) => index.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .columnsGap(0).rowsGap(0)
              .width('100%').height('100%')

              if (this.showOverlay) {
                Column() {
                  Text('坠毁了！').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
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
            .width('65%')
            .aspectRatio(0.5)
            .alignSelf(ItemAlign.Center)
          }
          .width('100%').backgroundColor('#1A1A2E').borderRadius(8)
          .height(450)
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
      .width('92%').layoutWeight(1).backgroundColor('#D4D0C8').borderRadius(24)
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
        if (this.spawnTimer > 0) { clearInterval(this.spawnTimer); }
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { vibrate(10); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { this.shoot(); vibrate(10); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
