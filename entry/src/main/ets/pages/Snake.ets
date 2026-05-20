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
    this.gameOver = false;
    this.showOverlay = false;
    this.paused = false;
    this.spawnFood();
    this.syncFlat();
    if (this.gameTimer > 0) {
      clearInterval(this.gameTimer);
    }
    this.gameTimer = setInterval(() => {
      this.tick();
    }, 250);
  }

  spawnFood(): void {
    let cells: number[] = [];
    for (let i = 0; i < this.gridSize * this.gridSize; i++) {
      let occupied = false;
      for (let j = 0; j < this.snake.length; j++) {
        if (this.snake[j] === i) {
          occupied = true;
          break;
        }
      }
      if (!occupied) {
        cells.push(i);
      }
    }
    if (cells.length > 0) {
      this.food = cells[Math.floor(Math.random() * cells.length)];
    }
  }

  tick(): void {
    if (this.gameOver || this.showOverlay || this.paused) {
      return;
    }

    this.dir = this.nextDirection;
    let head = this.snake[this.snake.length - 1];
    let row = Math.floor(head / this.gridSize);
    let col = head % this.gridSize;

    if (this.dir === 0) { row--; } // up
    if (this.dir === 1) { col++; } // right
    if (this.dir === 2) { row++; } // down
    if (this.dir === 3) { col--; } // left

    if (row < 0) { row = this.gridSize - 1; }
    if (row >= this.gridSize) { row = 0; }
    if (col < 0) { col = this.gridSize - 1; }
    if (col >= this.gridSize) { col = 0; }

    let newHead = row * this.gridSize + col;
    for (let i = 0; i < this.snake.length - 1; i++) {
      if (this.snake[i] === newHead) {
        this.endGame();
        return;
      }
    }

    let ate = newHead === this.food;
    this.snake.push(newHead);
    if (!ate) {
      this.snake.shift();
    } else {
      this.score++;
      vibrate(15);
      this.spawnFood();
    }
    this.snake = [...this.snake];
    this.syncFlat();
  }

  endGame(): void {
    this.gameOver = true;
    vibrate(300);
    setTimeout(() => { this.showOverlay = true; }, 200);
    if (this.gameTimer > 0) {
      clearInterval(this.gameTimer);
      this.gameTimer = -1;
    }
  }

  syncFlat(): void {
    let cells: number[] = [];
    let total = this.gridSize * this.gridSize;
    for (let i = 0; i < total; i++) {
      let isSnake = 0;
      for (let j = 0; j < this.snake.length; j++) {
        if (this.snake[j] === i) {
          isSnake = j === this.snake.length - 1 ? 2 : 1;
          break;
        }
      }
      if (i === this.food) {
        cells.push(3);
      } else if (isSnake === 2) {
        cells.push(2); // head
      } else if (isSnake === 1) {
        cells.push(1); // body
      } else {
        cells.push(0);
      }
    }
    this.flatCells = cells;
  }

  changeDirection(d: number): void {
    // prevent 180-degree turn
    if ((this.dir === 0 && d === 2) ||
        (this.dir === 2 && d === 0) ||
        (this.dir === 1 && d === 3) ||
        (this.dir === 3 && d === 1)) {
      return;
    }
    this.nextDirection = d;
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
          if (this.gameTimer > 0) {
            clearInterval(this.gameTimer);
          }
          try {
            this.getUIContext().getRouter().back();
          } catch (_) {}
        })

        Text('贪吃蛇')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#776E65')

        Text('长度: ' + (this.score + 3).toString())
          .fontSize(16)
          .fontColor('#776E65')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // Game grid
      Stack() {
        Grid() {
          ForEach(this.flatCells, (v: number, index: number) => {
            GridItem() {
              Stack() {
                Text(v === 3 ? '🍎' : v === 0 ? '' : '')
                  .width('100%')
                  .height('100%')
                  .fontSize(v === 3 ? 20 : 0)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height('100%')
              .borderRadius(4)
              .backgroundColor(v === 0 ? '#CDC1B4' : v === 1 ? '#8F7A66' : v === 2 ? '#6B5B4F' : '#FFFFFF')
            }
          }, (index: number) => index.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(2)
        .rowsGap(2)
        .width(310)
        .height(310)
        .backgroundColor('#BBADA0')
        .borderRadius(8)
        .padding(4)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down && event.touches.length > 0) {
            this.touchStartX = event.touches[0].x;
            this.touchStartY = event.touches[0].y;
          } else if (event.type === TouchType.Up && event.touches.length > 0) {
            let dx = event.touches[0].x - this.touchStartX;
            let dy = event.touches[0].y - this.touchStartY;
            if (Math.abs(dx) > 30 || Math.abs(dy) > 30) {
              if (Math.abs(dx) > Math.abs(dy)) {
                this.changeDirection(dx > 0 ? 1 : 3);
              } else {
                this.changeDirection(dy > 0 ? 2 : 0);
              }
            }
          }
        })

        if (this.gameOver || this.showOverlay) {
          Column() {
            Text('游戏结束')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#776E65')
            Text('长度: ' + (this.score + 3).toString())
              .fontSize(20)
              .fontColor('#CC4444')
              .margin({ top: 8 })
            Button() {
              Text('再来一局')
                .fontSize(16)
                .fontColor('#F9F6F2')
            }
            .backgroundColor('#8F7A66')
            .borderRadius(8)
            .margin({ top: 16 })
            .onClick(() => {
              this.startGame();
            })
          }
          .width(310)
          .height(310)
          .backgroundColor('#BAEEE4DA')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .borderRadius(8)
        }
      }
      .width(310)
      .height(310)

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
