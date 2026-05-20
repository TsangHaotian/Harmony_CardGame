import vibrator from '@ohos.vibrator';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

@Entry
@Component
struct About {
  build() {
    Column() {
      Column() {
        Scroll() {
        Column() {
        Column() {
          Column() {
            // Title area
            Column() {
              Text('CardGame').fontSize(22).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                .width('100%').textAlign(TextAlign.Center).margin({ top: 6 })

              Row() {}.width('80%').height(1).backgroundColor('#333333')
                .alignSelf(ItemAlign.Center)
                .margin({ top: 6, bottom: 8 })

              Text('版本 1.0.0').fontSize(14).fontColor('#8B8B9E').width('100%')
                .textAlign(TextAlign.Center)

              Row() {}.width('60%').height(1).backgroundColor('#333333')
                .alignSelf(ItemAlign.Center)
                .margin({ top: 8, bottom: 8 })

              // 游戏机装饰
              Row() {
                this.Pixel('#44DD44'); this.Pixel('#44DD44'); this.Pixel('#44DD44')
                this.Pixel('#1A1A2E'); this.Pixel('#DD4444'); this.Pixel('#FFDD44')
                this.Pixel('#1A1A2E'); this.Pixel('#4488CC'); this.Pixel('#4488CC')
              }
              .width('100%').justifyContent(FlexAlign.Center).margin({ top: 2, bottom: 6 })

              Scroll() {
              Column() {
                Text('— 操作说明 —').fontSize(14).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                  .width('100%').textAlign(TextAlign.Center).margin({ bottom: 5 })

                this.Entry('START', '开始 / 重新开始')
                this.Entry('BACK', '返回上级')
                this.Entry('←↑↓→', '方向控制')
                this.Entry('A', '确认 / 射击')
                this.Entry('B', '取消 / 特殊')

                Row() {}.width('40%').height(1).backgroundColor('#333333')
                  .alignSelf(ItemAlign.Center).margin({ top: 6, bottom: 6 })

                Text('— 游戏列表 —').fontSize(14).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
                  .width('100%').textAlign(TextAlign.Center).margin({ bottom: 5 })

                this.Entry('2048', '经典数字合并')
                this.Entry('扫雷', '经典逻辑推理')
                this.Entry('贪吃蛇', '经典贪吃游戏')
                this.Entry('俄罗斯方块', '经典下落拼图')
                this.Entry('打砖块', '经典弹球打砖')
                this.Entry('游戏1', '预留新游戏')
                this.Entry('游戏2', '预留新游戏')
                this.Entry('游戏3', '预留新游戏')
                this.Entry('游戏4', '预留新游戏')
                this.Entry('游戏5', '预留新游戏')
                this.Entry('游戏6', '预留新游戏')
                this.Entry('游戏7', '预留新游戏')
                this.Entry('赛车大赛', '躲避障碍物')
                this.Entry('飞机大战', '射击敌机')
              }
              .width('100%')
              }
              .width('100%').layoutWeight(1)

              Blank()

              Column() {
                Row() {
                  Text('作者 ').fontSize(12).fontColor('#888888')
                  Text('TsangHaotian').fontSize(12).fontColor('#4488CC').fontWeight(FontWeight.Bold)
                }
                .width('100%').justifyContent(FlexAlign.Center)

                Text('© 2026 Harmony GB · v1.0.0').fontSize(12).fontColor('#555555')
                  .width('100%').textAlign(TextAlign.Center).margin({ top: 2 })
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
          .clip(true)
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
      }
      }
      .width('92%').layoutWeight(1).constraintSize({ maxWidth: 540 }).backgroundColor('#D4D0C8').borderRadius(24)
    }
    .width('100%').height('100%').backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center).padding({ top: 40, bottom: 15 })
  }

  @Builder Pixel(c: string) {
    Text(' ').fontSize(6).width(14).height(14).backgroundColor(c).borderRadius(3).margin({ left: 2, right: 2 })
  }

  @Builder Entry(key: string, desc: string) {
    Row() {
      Text(key).fontSize(13).fontColor('#44DD44').fontWeight(FontWeight.Bold).width(60).textAlign(TextAlign.End)
      Text('  ' + desc).fontSize(13).fontColor('#CCCCCC')
    }
    .width('100%').padding({ top: 3, bottom: 3 }).margin({ left: 8 })
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
      .onClick(() => { vibrate(8); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { vibrate(8); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => {
        vibrate(10);
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
      .onClick(() => { vibrate(10); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
