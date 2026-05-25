import vibrator from '@ohos.vibrator';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { preferences } from '@kit.ArkData';

function vibrate(ms: number): void {
  try {
    vibrator.vibrate(ms);
  } catch (_) {}
}

let soundPool: media.SoundPool | null = null;
let soundId: number = 0;
let soundReady: boolean = false;

function initSound(): void {
  try {
    let info: audio.AudioRendererInfo = { usage: audio.StreamUsage.STREAM_USAGE_MUSIC, rendererFlags: 0 };
    media.createSoundPool(3, info).then((pool: media.SoundPool) => {
      soundPool = pool;
      let ctx = getContext();
      let rawFd = ctx.resourceManager.getRawFdSync('click.mp3');
      pool.load(rawFd.fd, rawFd.offset, rawFd.length).then((id: number) => {
        soundId = id;
        soundReady = true;
      });
    });
  } catch (_) {}
}
initSound();

function playClick(): void {
  try { vibrator.vibrate(8); } catch (_) {}
  if (soundReady && soundPool) {
    try { soundPool.play(soundId, { loop: 0, leftVolume: 1.0, rightVolume: 1.0 }); } catch (_) {}
  }
}


class GameEntry {
  title: string = '';
  page: string = '';
}

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @StorageLink('needPrivacy') needPrivacy: boolean = true;
  @State showPrivacy: boolean = false;
  @State privacyOut: boolean = false;
  private scroller: Scroller = new Scroller();

  private games: GameEntry[] = [
    { title: '五子棋', page: 'pages/Gomoku' },
    { title: '2048', page: 'pages/Game2048' },
    { title: '扫雷', page: 'pages/Minesweeper' },
    { title: '飞机大战', page: 'pages/PlaneBattle' },
    { title: '贪吃蛇', page: 'pages/Snake' },
    { title: '围棋', page: 'pages/Go' },
    { title: '吃豆人', page: 'pages/Pacman' },
    { title: '俄罗斯方块', page: 'pages/Tetris' },
    { title: '打砖块', page: 'pages/Breakout' },
    { title: '井字棋', page: 'pages/TicTacToe' },
    { title: '赛车大赛', page: 'pages/CarRacer' },
    { title: '华容道', page: 'pages/Klotski' },
    { title: '关于', page: 'pages/About' }
  ];

  aboutToAppear(): void {
    if (this.needPrivacy) {
      this.showPrivacy = true;
    }
  }

  async onPrivacyAgree(): Promise<void> {
    try {
      let ctx = getContext();
      let store = await preferences.getPreferences(ctx, 'privacy_store');
      await store.put('agreedPrivacy', true);
      await store.flush();
    } catch (_) {}
    this.privacyOut = true;
    setTimeout(() => {
      this.showPrivacy = false;
      this.needPrivacy = false;
    }, 300);
  }

  onPrivacyDisagree(): void {
    try {
      AlertDialog.show({
        title: '提示',
        message: '需要同意隐私政策才能使用本应用',
        confirm: {
          value: '知道了',
          action: () => {}
        }
      });
    } catch (_) {}
  }

  autoScroll(): void {
    let itemH = 36;
    let visible = 8;
    if (this.selectedIndex >= visible) {
      this.scroller.scrollTo({ xOffset: 0, yOffset: (this.selectedIndex - visible + 1) * itemH, animation: { duration: 100 } });
    } else {
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 100 } });
    }
  }

  moveUp(): void {
    if (this.selectedIndex > 0) {
      this.selectedIndex--;
      playClick();
      this.autoScroll();
    }
  }

  moveDown(): void {
    if (this.selectedIndex < this.games.length - 1) {
      this.selectedIndex++;
      this.autoScroll();
      playClick();
    }
  }

  selectGame(): void {
    playClick();
    try {
      this.getUIContext().getRouter().pushUrl({ url: this.games[this.selectedIndex].page });
    } catch (_) {}
  }

  goBack(): void {
    playClick();
    try {
      this.getUIContext().getRouter().back();
    } catch (_) {}
  }

  build() {
    Stack() {
      // 主界面 - 始终加载
      Column() {
        Column() {
          Scroll() {
          Column() {
          Column() {
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

              Scroll(this.scroller) {
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
            .clip(true)
            .padding({ top: 10, bottom: 8, left: 12, right: 12 })
          }
          .backgroundColor('#444444')
          .borderRadius(12)
          .padding(8)
          .margin({ top: 20, left: 16, right: 16 })

          Row() { this.StartSelectLayout() }
            .padding({ top: 14, bottom: 4 })

          Row() {
            this.DPadLayout()
            Blank().layoutWeight(1)
            this.ActionButtonLayout()
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 24, bottom: 4 })

          Text('HARMONY GB')
            .fontSize(11)
            .fontColor('#888888')
            .margin({ bottom: 6 })
        }
        .width('92%')
        .layoutWeight(1)
        .constraintSize({ maxWidth: 540 })
        .backgroundColor('#D4D0C8')
        .borderRadius(24)
      }
      }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#2B2B2B')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 40, bottom: 15 })

      // 隐私政策覆盖层 - 叠在主界面之上
      if (this.showPrivacy) {
        Column() {
          Column() {
            Text('隐私政策')
              .fontSize(22)
              .fontColor('#FF6B35')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 0, bottom: 8 })

            Row() {}.width('80%').height(1).backgroundColor('#444444')
          }
          .width('100%')
          .padding({ top: 24, bottom: 12 })

          Scroll() {
            Column() {
              Text('最后更新日期：2026年5月')
                .fontSize(12).fontColor('#888888').width('100%').margin({ bottom: 12 })

              Text('欢迎使用 CardGame（以下简称"本应用"）。我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('一、信息收集与使用')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('本应用为本地运行的离线游戏集合，不收集任何个人身份信息。我们不会收集、存储或上传您的姓名、地址、电子邮件、电话号码、位置信息等个人数据。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('二、本地数据存储')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('本应用会使用本地存储（PersistentStorage）保存您的游戏进度和最高分记录。这些数据仅存储在您的设备本地，不会传输到任何服务器。您可以随时在系统设置中清除应用数据以删除这些信息。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('三、权限说明')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('本应用需要振动权限（ohos.permission.VIBRATE）用于游戏中的触感反馈。此权限仅用于本地振动反馈，不会收集或传输任何信息。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('四、第三方服务')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('本应用不集成任何第三方统计分析服务、广告SDK或社交分享SDK。所有功能均在本地运行，无需网络连接。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('五、儿童隐私')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('本应用不会故意收集儿童的个人信息。由于本应用不收集任何用户信息，所有年龄段用户均可安全使用。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('六、隐私政策更新')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('我们可能会不时更新本隐私政策。更新后的隐私政策将在应用内公布。重大变更时，我们会通过应用内提示通知您。继续使用本应用即表示您同意更新后的政策。')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })

              Text('七、联系我们')
                .fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 6 })

              Text('如您对本隐私政策有任何疑问，请通过以下方式联系我们：\n邮箱：TsangHaotian@example.com')
                .fontSize(14).fontColor('#CCCCCC').width('100%').lineHeight(22).margin({ bottom: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .layoutWeight(1)
          .width('100%')

          Row() {}.width('100%').height(1).backgroundColor('#444444').margin({ bottom: 12 })

          Row() {
            Button() {
              Text('不同意').fontSize(15).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
            }
            .width(110).height(42).backgroundColor('#666666').borderRadius(21)
            .onClick(() => { this.onPrivacyDisagree(); })

            Blank().layoutWeight(1)

            Button() {
              Text('同意并继续').fontSize(15).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
            }
            .width(130).height(42).backgroundColor('#FF6B35').borderRadius(21)
            .onClick(() => { this.onPrivacyAgree(); })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A2E')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 40, left: 20, right: 20, bottom: 20 })
        .translate({ y: this.privacyOut ? -100 : 0 })
        .opacity(this.privacyOut ? 0 : 1)
        .animation({ duration: 300, curve: Curve.Friction })
      }
    }
    .width('100%')
    .height('100%')
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
      .onClick(() => { if (this.selectedIndex > 0) { this.selectedIndex = 0; playClick(); this.autoScroll(); } })
      Button() {
        Image($r('app.media.icon_right')).width(60).height(60)
      }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0)
.offset({ x: 42 })
      .onClick(() => { if (this.selectedIndex < this.games.length - 1) { this.selectedIndex = this.games.length - 1; playClick(); this.autoScroll(); } })
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
      .onClick(() => { playClick(); })

      Stack() {
        Circle().width(64).height(64).fill('#CC4444')
        Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      }
      .margin({ left: 12 })
      .onClick(() => { this.selectGame(); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 200, curve: Curve.Friction })
    PageTransitionExit({ duration: 150, curve: Curve.Friction })
  }
}
