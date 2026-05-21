@Entry
@Component
struct WidgetCard {
  build() {
    Column() {
      Row() {}.width('100%').height(5).backgroundColor('#FF6B35').borderRadius({ topLeft: 14, topRight: 14 })

      Column() {
        Row() {
          // 左侧屏幕
          Column() {
            Row() {
              Text('TETRIS').fontSize(8).fontColor('#FF6B35').fontWeight(FontWeight.Bold).letterSpacing(1)
              Blank()
              Text('0').fontSize(7).fontColor('#FFD700').fontWeight(FontWeight.Bold)
            }
            .width('100%').padding({ bottom: 2 })

            Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceEvenly }) {
              this.PixLine('.........')
              this.PixLine('.........')
              this.PixLine('.........')
              this.PixLine('.....###.')
              this.PixLine('.....#.#.')
              this.PixLine('....##.#.')
              this.PixLine('....#....')
              this.PixLine('...###...')
              this.PixLine('...##....')
              this.PixLine('..####...')
              this.PixLine('..###....')
              this.PixLine('.##.##...')
              this.PixLine('.##.##...')
              this.PixLine('###.##...')
              this.PixLine('####.#.##')
              this.PixLine('########.')
              this.PixLine('#####.###')
              this.PixLine('########.')
              this.PixLine('#########')
              this.PixLine('###.####.')
            }
            .width('100%').layoutWeight(1)
          }
          .width('54%').height('100%').backgroundColor('#1A1A2E').borderRadius(6).padding(4)

          Blank()

          // 右侧操作区
          Column() {
            // D-Pad
            Stack() {
              Circle().width(32).height(32).fill('#555555')
              Circle().width(10).height(10).fill('#888888')
              // 方向指示
              Text('▴').fontSize(8).fontColor('#AAAAAA').offset({ y: -14 })
              Text('▾').fontSize(8).fontColor('#AAAAAA').offset({ y: 12 })
              Text('◂').fontSize(8).fontColor('#AAAAAA').offset({ x: -14 })
              Text('▸').fontSize(8).fontColor('#AAAAAA').offset({ x: 14 })
            }
            .width(44).height(44)

            // A/B 按钮
            Row() {
              Stack() { Circle().width(18).height(18).fill('#4488CC'); Text('B').fontSize(7).fontColor('#FFFFFF') }
              Stack() { Circle().width(22).height(22).fill('#CC4444'); Text('A').fontSize(8).fontColor('#FFFFFF') }.margin({ left: 6 })
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          .width('36%')
        }
        .width('100%').layoutWeight(1)
      }
      .width('100%').layoutWeight(1).backgroundColor('#D4D0C8').padding(8)

      Row() {}.width('100%').height(3).backgroundColor('#444444').borderRadius({ bottomLeft: 14, bottomRight: 14 })
    }
    .width('100%').height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {}
      });
    })
  }

  @Builder PixLine(pattern: string) {
    Row() {
      ForEach(pattern.split(''), (ch: string) => {
        Text(' ').fontSize(2).width(5).height(5).margin(0.5)
          .backgroundColor(ch === '#' ? '#44DDDD' : '#1A1A2E')
      }, (ch: string, i: number) => i.toString())
    }
    .width('100%').justifyContent(FlexAlign.Center)
  }
}
