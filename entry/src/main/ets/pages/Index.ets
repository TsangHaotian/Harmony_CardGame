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
    { title: '扫雷', page: 'pages/Minesweeper' },
    { title: '飞机大战', page: 'pages/PlaneBattle' },
    { title: '贪吃蛇', page: 'pages/Snake' },
    { title: '俄罗斯方块', page: 'pages/Tetris' },
    { title: '打砖块', page: 'pages/Breakout' },
    { title: '赛车大赛', page: 'pages/CarRacer' },
    { title: '关于', page: 'pages/About' }
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
          .height(450)
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
        .padding({ top: 14, bottom: 4 })

        // Bottom section: D-Pad left, A/B right
        Row() {
          this.DPadLayout()
          Blank()
            .layoutWeight(1)
          this.ActionButtonLayout()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 24, bottom: 4 })

        // Brand
        Text('HARMONY GB')
          .fontSize(11)
          .fontColor('#888888')
          .margin({ bottom: 6 })
      }
      .width('92%')
      .layoutWeight(1)
      .backgroundColor('#D4D0C8')
      .borderRadius(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 40, bottom: 15 })
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
      Button() {
        Image($r('app.media.icon_up')).width(60).height(60)
      }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0)
.offset({ y: -42 })
      .onClick(() => { this.moveUp(); })
      Button() {
        Image($r('app.media.icon_down')).width(60).height(60)
      }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0)
.offset({ y: 42 })
      .onClick(() => { this.moveDown(); })
      Button() {
        Image($r('app.media.icon_left')).width(60).height(60)
      }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0)
.offset({ x: -42 })
      .onClick(() => { if (this.selectedIndex > 0) { this.selectedIndex = 0; vibrate(8); } })
      Button() {
        Image($r('app.media.icon_right')).width(60).height(60)
      }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0)
.offset({ x: 42 })
      .onClick(() => { if (this.selectedIndex < this.games.length - 1) { this.selectedIndex = this.games.length - 1; vibrate(8); } })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() {
        Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.selectGame(); })

      Button() {
        Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14)
      .margin({ left: 16 })
      .onClick(() => { this.goBack(); })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() {
        Circle().width(56).height(56).fill('#4488CC')
        Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .onClick(() => { vibrate(10); })

      Stack() {
        Circle().width(64).height(64).fill('#CC4444')
        Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .margin({ left: 12 })
      .onClick(() => { this.selectGame(); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
