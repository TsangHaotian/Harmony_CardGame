import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

class GameEntry {
  title: string = '';
  page: string = '';
}

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;

  private games: GameEntry[] = [
    { title: '2048', page: 'pages/Game2048' },
    { title: 'Minesweeper', page: 'pages/Minesweeper' },
    { title: '打地鼠', page: 'pages/WhackAMole' },
    { title: '贪吃蛇', page: 'pages/Snake' },
    { title: '赛车大赛', page: 'pages/CarRacer' }
  ];

  moveUp(): void {
    if (this.selectedIndex > 0) {
      this.selectedIndex--;
      vibrate(8);
    }
  }

  moveDown(): void {
    if (this.selectedIndex < this.games.length - 1) {
      this.selectedIndex++;
      vibrate(8);
    }
  }

  selectGame(): void {
    vibrate(15);
    try {
      this.getUIContext().getRouter().pushUrl({ url: this.games[this.selectedIndex].page });
    } catch (_) {}
  }

  goBack(): void {
    vibrate(10);
    try {
      this.getUIContext().getRouter().back();
    } catch (_) {}
  }

  build() {
    Stack() {
      Column() {
        // Console body
        Column() {
          // Screen bezel
          Column() {
            // Screen
            Column() {
              Row() {
                Text('GAME LIST')
                  .fontSize(14)
                  .fontColor('#FF6B35')
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Scroll() {
                Column() {
                  ForEach(this.games, (game: GameEntry, index: number) => {
                    this.GameListItem(game.title, index)
                  }, (game: GameEntry, index: number) => index.toString())
                }
                .width('100%')
              }
              .width('100%')
              .layoutWeight(1)
            }
            .width('100%')
            .height(280)
            .backgroundColor('#1A1A2E')
            .borderRadius(8)
            .padding({ top: 10, bottom: 8, left: 12, right: 12 })
          }
          .backgroundColor('#444444')
          .borderRadius(12)
          .padding(8)
          .margin({ top: 20, left: 16, right: 16 })

          // Start / Select in the middle gap
          Row() {
            this.StartSelectLayout()
          }
          .padding({ top: 4, bottom: 4 })

          // Bottom section: D-Pad left, A/B right
          Row() {
            this.DPadLayout()
            Blank()
              .layoutWeight(1)
            this.ActionButtonLayout()
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 24, bottom: 8 })

          // Brand
          Text('HARMONY GB')
            .fontSize(11)
            .fontColor('#888888')
            .margin({ bottom: 10 })
        }
        .width('92%')
        .height('85%')
        .backgroundColor('#D4D0C8')
        .borderRadius(24)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2B2B2B')
  }

  @Builder GameListItem(title: string, index: number) {
    Row() {
      if (index === this.selectedIndex) {
        Text('>')
          .fontSize(18)
          .fontColor('#FF6B35')
          .fontWeight(FontWeight.Bold)
          .margin({ right: 4 })
      }
      Text(title)
        .fontSize(index === this.selectedIndex ? 18 : 16)
        .fontColor(index === this.selectedIndex ? '#FFFFFF' : '#8B8B9E')
        .fontWeight(index === this.selectedIndex ? FontWeight.Bold : FontWeight.Regular)
      if (index === this.selectedIndex) {
        Text('<')
          .fontSize(18)
          .fontColor('#FF6B35')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
      }
      Blank()
    }
    .width('100%')
    .height(32)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectedIndex = index;
      this.selectGame();
    })
  }

  @Builder DPadLayout() {
    Stack() {
      Circle()
        .width(100)
        .height(100)
        .fill('#3A3A3A')
      // Up
      Button() {
        Text('▲').fontSize(24).fontColor('#CCCCCC')
      }
      .width(60).height(44).backgroundColor('#555555').borderRadius(8)
      .offset({ y: -56 })
      .onClick(() => { this.moveUp(); })
      // Down
      Button() {
        Text('▼').fontSize(24).fontColor('#CCCCCC')
      }
      .width(60).height(44).backgroundColor('#555555').borderRadius(8)
      .offset({ y: 56 })
      .onClick(() => { this.moveDown(); })
      // Left
      Button() {
        Text('◀').fontSize(24).fontColor('#CCCCCC')
      }
      .width(44).height(60).backgroundColor('#555555').borderRadius(8)
      .offset({ x: -56 })
      .onClick(() => { if (this.selectedIndex > 0) { this.selectedIndex = 0; vibrate(8); } })
      // Right
      Button() {
        Text('▶').fontSize(24).fontColor('#CCCCCC')
      }
      .width(44).height(60).backgroundColor('#555555').borderRadius(8)
      .offset({ x: 56 })
      .onClick(() => { if (this.selectedIndex < this.games.length - 1) { this.selectedIndex = this.games.length - 1; vibrate(8); } })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() {
        Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#666666').borderRadius(14)
      .onClick(() => { this.selectGame(); })

      Button() {
        Text('SELECT').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#666666').borderRadius(14)
      .margin({ left: 16 })
      .onClick(() => { this.goBack(); })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() {
        Circle().width(56).height(56).fill('#E84855')
        Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .onClick(() => { this.goBack(); })

      Stack() {
        Circle().width(64).height(64).fill('#4ECDC4')
        Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .margin({ left: 12 })
      .onClick(() => { this.selectGame(); })
    }
  }
}
