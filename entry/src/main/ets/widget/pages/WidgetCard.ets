@Entry
@Component
struct WidgetCard {
  build() {
    Column() {
      Row() {}.width('100%').height(6).backgroundColor('#FF6B35').borderRadius({ topLeft: 16, topRight: 16 })

      Column() {
        Row() {
          // 左侧：D-Pad
          Column() {
            Circle().width(10).height(10).fill('#555555')
            Row() {
              Circle().width(10).height(10).fill('#555555')
              Circle().width(14).height(14).fill('#666666')
              Circle().width(10).height(10).fill('#555555')
            }
            .width(34).justifyContent(FlexAlign.SpaceBetween).margin({ top: 2 })
            Circle().width(10).height(10).fill('#555555').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center).height('100%').width('24%')

          // 屏幕
          Column() {
            Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceEvenly }) {
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
                this.Pix('#44DD44'); this.Pix('#44DD44'); this.Pix('#44DD44'); this.Pix('#1A1A2E'); this.Pix('#DD4444')
              }
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
                this.Pix('#44DD44'); this.Pix('#1A1A2E'); this.Pix('#44DD44'); this.Pix('#1A1A2E'); this.Pix('#1A1A2E')
              }
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
                this.Pix('#1A1A2E'); this.Pix('#44DD44'); this.Pix('#1A1A2E'); this.Pix('#1A1A2E'); this.Pix('#1A1A2E')
              }
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
                this.Pix('#1A1A2E'); this.Pix('#1A1A2E'); this.Pix('#1A1A2E'); this.Pix('#FFDD44'); this.Pix('#1A1A2E')
              }
            }.width('100%').layoutWeight(1)
          }
          .width('50%').height('100%').backgroundColor('#1A1A2E').borderRadius(6).padding(4)

          // 右侧 A/B
          Column() {
            Circle().width(18).height(18).fill('#CC4444')
            Circle().width(14).height(14).fill('#4488CC').margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Center).height('100%').width('26%').justifyContent(FlexAlign.Center)
        }
        .width('100%').layoutWeight(1)
      }
      .width('100%').layoutWeight(1).backgroundColor('#D4D0C8').padding(10)

      Row() {}.width('100%').height(4).backgroundColor('#444444').borderRadius({ bottomLeft: 16, bottomRight: 16 })
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

  @Builder Pix(c: string) {
    Text(' ').fontSize(4).width(12).height(12).backgroundColor(c).borderRadius(2)
  }
}
