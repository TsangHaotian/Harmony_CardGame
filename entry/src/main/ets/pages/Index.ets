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
        .margin({ top: 8, bottom: 16 })

      Scroll() {
        Column() {
          this.GameCard('2048', '合并数字到达 2048！', '#EDCF72', 'pages/Game2048')
          this.GameCard('Minesweeper', '找出所有地雷！', '#A0D0A0', 'pages/Minesweeper')
          this.GameCard('打地鼠', '敲打冒头的地鼠！', '#C8A050', 'pages/WhackAMole')
          this.GameCard('贪吃蛇', '滑动控制蛇吃食物！', '#D08080', 'pages/Snake')
          this.GameCard('赛车大赛', '左右闪避障碍物！', '#6688CC', 'pages/CarRacer')
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)

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

  @Builder GameCard(title: string, desc: string, color: string, page: string) {
    Column() {
      Text(title)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
      Text(desc)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width(280)
    .height(120)
    .backgroundColor(color)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ top: 20 })
    .onClick(() => {
      try {
        this.getUIContext().getRouter().pushUrl({ url: page });
      } catch (_) {}
    })
  }
}
