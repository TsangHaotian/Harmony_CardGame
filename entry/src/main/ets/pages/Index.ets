@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Mini Games')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 60 })

      Text('离线小游戏，点开即玩')
        .fontSize(16)
        .fontColor('#888888')
        .margin({ top: 8, bottom: 40 })

      Column() {
        Column() {
          Text('2048')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
          Text('合并数字到达 2048！')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width(280)
        .height(120)
        .backgroundColor('#EDCF72')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.openGame();
        })

        Column() {
          Text('Minesweeper')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
          Text('找出所有地雷！')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width(280)
        .height(120)
        .backgroundColor('#A0D0A0')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Minesweeper' });
          } catch (_) {}
        })
        .margin({ top: 20 })
      }

      Blank()

      Text('v1.0.0')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
    .alignItems(HorizontalAlign.Center)
  }

  openGame(): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/Game2048' });
    } catch (_) {}
  }
}
