import vibrator from '@ohos.vibrator';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';

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

class Piece {
  id: number = 0;
  label: string = '';
  w: number = 1;
  h: number = 1;
  x: number = 0;
  y: number = 0;
}

function levelBoard(lv: number): number[] {
  if (lv <= 3) return [4, 5, 0, 3]; // cols, rows, exitX, exitY
  if (lv <= 6) return [6, 7, 2, 5];
  return [8, 8, 1, 6];
}

function levelShuffleSteps(lv: number): number {
  if (lv <= 3) return [8, 15, 25][lv - 1];
  if (lv <= 6) return [30, 50, 70][lv - 4];
  let steps = 50 + (lv - 7) * 20;
  if (steps > 120) steps = 120;
  return steps;
}

function createLevelPieces(lv: number, cols: number): Piece[] {
  if (lv <= 3) {
    return [
      { id: 1, label: '曹操', w: 2, h: 2, x: 0, y: 0 },
      { id: 2, label: '关羽', w: 2, h: 1, x: 0, y: 2 },
      { id: 3, label: '赵云', w: 1, h: 2, x: 2, y: 0 },
      { id: 4, label: '马超', w: 1, h: 2, x: 2, y: 3 },
      { id: 5, label: '兵甲', w: 1, h: 1, x: 0, y: 3 },
    ];
  }
  if (lv <= 6) {
    return [
      { id: 1, label: '曹操', w: 2, h: 2, x: 2, y: 0 },
      { id: 2, label: '关羽', w: 2, h: 1, x: 0, y: 2 },
      { id: 3, label: '张飞', w: 2, h: 1, x: 4, y: 2 },
      { id: 4, label: '赵云', w: 1, h: 2, x: 0, y: 3 },
      { id: 5, label: '马超', w: 1, h: 2, x: 3, y: 3 },
      { id: 6, label: '黄忠', w: 1, h: 2, x: 5, y: 0 },
      { id: 7, label: '魏延', w: 1, h: 2, x: 0, y: 0 },
      { id: 8, label: '兵甲', w: 1, h: 1, x: 1, y: 5 },
      { id: 9, label: '兵乙', w: 1, h: 1, x: 4, y: 5 },
      { id: 10, label: '兵丙', w: 1, h: 1, x: 2, y: 4 },
      { id: 11, label: '兵丁', w: 1, h: 1, x: 3, y: 4 },
      { id: 12, label: '兵戊', w: 1, h: 1, x: 1, y: 3 },
      { id: 13, label: '兵己', w: 1, h: 1, x: 5, y: 4 },
    ];
  }
  // 8x8
  return [
    { id: 1, label: '曹操', w: 2, h: 2, x: 1, y: 0 },
    { id: 2, label: '关羽', w: 2, h: 1, x: 0, y: 2 },
    { id: 3, label: '马超', w: 2, h: 1, x: 6, y: 2 },
    { id: 4, label: '张飞', w: 1, h: 2, x: 0, y: 0 },
    { id: 5, label: '赵云', w: 1, h: 2, x: 3, y: 0 },
    { id: 6, label: '黄忠', w: 1, h: 2, x: 6, y: 0 },
    { id: 7, label: '魏延', w: 1, h: 2, x: 0, y: 4 },
    { id: 8, label: '许褚', w: 2, h: 2, x: 6, y: 4 },
    { id: 9, label: '兵甲', w: 1, h: 1, x: 0, y: 3 },
    { id: 10, label: '兵乙', w: 1, h: 1, x: 7, y: 3 },
    { id: 11, label: '兵丙', w: 1, h: 1, x: 1, y: 6 },
    { id: 12, label: '兵丁', w: 1, h: 1, x: 0, y: 7 },
    { id: 13, label: '兵戊', w: 1, h: 1, x: 7, y: 7 },
    { id: 14, label: '兵己', w: 1, h: 1, x: 3, y: 4 },
    { id: 15, label: '兵庚', w: 1, h: 1, x: 4, y: 4 },
    { id: 16, label: '兵辛', w: 1, h: 1, x: 2, y: 3 },
  ];
}

function repeatStr(s: string, n: number): string {
  let r = '';
  for (let i = 0; i < n; i++) { r += s; }
  return r;
}

@Entry
@Component
struct Klotski {
  @State flatGrid: number[] = [];
  @State pieces: Piece[] = [];
  @State selectedId: number = -1;
  @State moves: number = 0;
  @State gameOver: boolean = false;
  @State showOverlay: boolean = false;
  @State bestMoves: number = AppStorage.get<number>('BestKlotski') ?? 0;
  @State lastMoves: number = 0;
  @State cursorX: number = 0;
  @State cursorY: number = 0;
  @State level: number = 1;
  @State gridCols: number = 4;
  @State gridRows: number = 5;
  @StorageLink('KlotskiLevel') maxLevel: number = 1;

  private exitX: number = 0;
  private exitY: number = 3;

  aboutToAppear(): void {
    this.startLevel(1);
  }

  startLevel(lv: number): void {
    this.level = lv;
    let board = levelBoard(lv);
    this.gridCols = board[0];
    this.gridRows = board[1];
    this.exitX = board[2];
    this.exitY = board[3];
    this.pieces = createLevelPieces(lv, this.gridCols);
    this.selectedId = -1;
    this.moves = 0;
    this.gameOver = false;
    this.showOverlay = false;
    this.lastMoves = 0;
    this.cursorX = 0;
    this.cursorY = 0;
    let steps = levelShuffleSteps(lv);
    this.shufflePieces(steps);
    this.renderGrid();
  }

  restartLevel(): void {
    this.startLevel(this.level);
  }

  nextLevel(): void {
    let next = this.level + 1;
    if (next > this.maxLevel) {
      this.maxLevel = next;
      AppStorage.set<number>('KlotskiLevel', this.maxLevel);
    }
    this.startLevel(next);
  }

  renderGrid(): void {
    let g: number[] = new Array(this.gridRows * this.gridCols).fill(0);
    for (let p of this.pieces) {
      for (let r = p.y; r < p.y + p.h; r++) {
        for (let c = p.x; c < p.x + p.w; c++) {
          g[r * this.gridCols + c] = p.id;
        }
      }
    }
    this.flatGrid = g;
  }

  shufflePieces(steps: number): void {
    let dirs: number[][] = [[0, -1], [0, 1], [-1, 0], [1, 0]];
    for (let s = 0; s < steps; s++) {
      let movable: number[] = [];
      for (let p of this.pieces) {
        for (let d of dirs) {
          if (this.canMovePiece(p.id, d[0], d[1])) {
            movable.push(p.id);
            break;
          }
        }
      }
      if (movable.length === 0) break;
      let pick = movable[Math.floor(Math.random() * movable.length)];
      let d = dirs[Math.floor(Math.random() * dirs.length)];
      if (this.canMovePiece(pick, d[0], d[1])) {
        let pp = this.pieces.find(p => p.id === pick);
        if (pp) { pp.x += d[0]; pp.y += d[1]; }
      } else { s--; }
    }
  }

  canMovePiece(id: number, dx: number, dy: number): boolean {
    let p = this.pieces.find(pp => pp.id === id);
    if (!p) return false;
    let nx = p.x + dx;
    let ny = p.y + dy;
    if (nx < 0 || ny < 0 || nx + p.w > this.gridCols || ny + p.h > this.gridRows) return false;
    for (let pp of this.pieces) {
      if (pp.id === id) continue;
      if (nx < pp.x + pp.w && nx + p.w > pp.x && ny < pp.y + pp.h && ny + p.h > pp.y) return false;
    }
    return true;
  }

  moveCursor(dx: number, dy: number): void {
    if (this.gameOver || this.showOverlay) { playClick(); return; }
    if (this.selectedId > 0) {
      if (this.canMovePiece(this.selectedId, dx, dy)) {
        let newPieces: Piece[] = [];
        for (let pp of this.pieces) {
          if (pp.id === this.selectedId) {
            newPieces.push({ id: pp.id, label: pp.label, w: pp.w, h: pp.h, x: pp.x + dx, y: pp.y + dy });
          } else {
            newPieces.push({ id: pp.id, label: pp.label, w: pp.w, h: pp.h, x: pp.x, y: pp.y });
          }
        }
        this.pieces = newPieces;
        this.moves++;
        this.renderGrid();
        playClick();
        this.checkWin();
      } else {
        playClick();
      }
    } else {
      let nx = this.cursorX + dx;
      let ny = this.cursorY + dy;
      if (nx >= 0 && nx < this.gridCols && ny >= 0 && ny < this.gridRows) {
        this.cursorX = nx;
        this.cursorY = ny;
        this.renderGrid();
        playClick();
      }
    }
  }

  pressA(): void {
    if (this.gameOver || this.showOverlay) { playClick(); return; }
    if (this.selectedId > 0) {
      let idAtCursor = this.pieceAt(this.cursorX, this.cursorY);
      if (idAtCursor > 0 && idAtCursor !== this.selectedId) {
        this.selectedId = idAtCursor;
        this.renderGrid();
        playClick();
      } else {
        playClick();
      }
    } else {
      let idAtCursor = this.pieceAt(this.cursorX, this.cursorY);
      if (idAtCursor > 0) {
        this.selectedId = idAtCursor;
        this.renderGrid();
        playClick();
      } else {
        playClick();
      }
    }
  }

  pressB(): void {
    if (this.gameOver || this.showOverlay) { playClick(); return; }
    if (this.selectedId > 0) {
      this.selectedId = -1;
      this.renderGrid();
      playClick();
    }
  }

  pieceAt(px: number, py: number): number {
    for (let p of this.pieces) {
      if (px >= p.x && px < p.x + p.w && py >= p.y && py < p.y + p.h) {
        return p.id;
      }
    }
    return 0;
  }

  checkWin(): void {
    let cao = this.pieces.find(p => p.id === 1);
    if (cao && cao.x === this.exitX && cao.y === this.exitY) {
      this.gameOver = true;
      playClick();
      try { vibrator.vibrate(300); } catch (_) {}
      this.lastMoves = this.moves;
      if (this.bestMoves === 0 || this.moves < this.bestMoves) {
        this.bestMoves = this.moves;
        AppStorage.set<number>('BestKlotski', this.bestMoves);
      }
      let nxt = this.level + 1;
      if (nxt > this.maxLevel) {
        this.maxLevel = nxt;
        AppStorage.set<number>('KlotskiLevel', this.maxLevel);
      }
      setTimeout(() => { this.showOverlay = true; }, 400);
    }
  }

  isCursorAt(i: number): boolean {
    let r = Math.floor(i / this.gridCols);
    let c = i % this.gridCols;
    return c === this.cursorX && r === this.cursorY;
  }

  isExitZone(i: number): boolean {
    let r = Math.floor(i / this.gridCols);
    let c = i % this.gridCols;
    return c >= this.exitX && c < this.exitX + 2 && r >= this.exitY;
  }

  cellBg(v: number, i: number): string {
    if (v === 0) {
      if (this.isCursorAt(i)) return '#3A3A5E';
      if (this.isExitZone(i) && !this.gameOver) return '#2A1A1A';
      return '#1A1A2E';
    }
    if (v === this.selectedId) return '#FFD700';
    if (v === 1) return '#CC4444';
    if (v === 2 || v === 3) return '#27AE60';
    if (v >= 4 && v <= 8) return '#3498DB';
    return '#8B8B9E';
  }

  cellText(v: number): string {
    let p = this.pieces.find(pp => pp.id === v);
    return p ? p.label : '';
  }

  selectedLabel(): string {
    let p = this.pieces.find(pp => pp.id === this.selectedId);
    return p ? p.label : '';
  }

  build() {
    Column() {
      Column() {
        Scroll() {
        Column() {
        Column() {
          Column() {
            // Score bar
            Row() {
              Text('华容道').fontSize(16).fontColor('#FF6B35').fontWeight(FontWeight.Bold)
              Text(' 第').fontSize(11).fontColor('#8B8B9E')
              Text(this.level.toString()).fontSize(11).fontColor('#FFD700').fontWeight(FontWeight.Bold)
              Text('关').fontSize(11).fontColor('#8B8B9E')
              Text('  ' + this.gridCols + '×' + this.gridRows).fontSize(10).fontColor('#666666')
              Blank()
              Text('步数: ').fontSize(11).fontColor('#8B8B9E')
              Text(this.moves.toString()).fontSize(11).fontColor('#FFD700').fontWeight(FontWeight.Bold)
              Text('  BEST ').fontSize(10).fontColor('#8B8B9E').margin({ left: 4 })
              Text(this.bestMoves > 0 ? this.bestMoves.toString() : '--').fontSize(10).fontColor('#FFD700').fontWeight(FontWeight.Bold)
              Text('  LAST ').fontSize(10).fontColor('#8B8B9E').margin({ left: 2 })
              Text(this.lastMoves > 0 ? this.lastMoves.toString() : '--').fontSize(10).fontColor('#888888')
            }
            .width('100%')
            .margin({ bottom: 4 })

            // Hint text
            if (this.selectedId > 0) {
              Text('已选中 ' + this.selectedLabel() + '  方向键移动')
                .fontSize(10).fontColor('#FFD700').width('100%').textAlign(TextAlign.Center)
                .margin({ bottom: 2 })
            } else {
              Text('方向键移动光标  A选中  B取消')
                .fontSize(10).fontColor('#8B8B9E').width('100%').textAlign(TextAlign.Center)
                .margin({ bottom: 2 })
            }
            Text('目标: 曹操到达底部 ⬇ 出口')
              .fontSize(9).fontColor('#FF6B35').width('100%').textAlign(TextAlign.Center)
              .margin({ bottom: 2 })

            // Game grid
            Stack() {
              Grid() {
                ForEach(this.flatGrid, (v: number, i: number) => {
                  GridItem() {
                    Stack() {
                      if (this.cellText(v).length > 0) {
                        Text(this.cellText(v))
                          .fontSize(v === 1 ? (this.gridCols <= 4 ? 16 : this.gridCols <= 6 ? 14 : 10) : (this.gridCols <= 4 ? 12 : this.gridCols <= 6 ? 9 : 7))
                          .fontColor('#FFFFFF')
                          .fontWeight(FontWeight.Bold)
                      } else if (this.isExitZone(i) && !this.gameOver) {
                        Text('⬇')
                          .fontSize(this.gridCols <= 4 ? 10 : this.gridCols <= 6 ? 8 : 6)
                          .fontColor('#CC444466').fontWeight(FontWeight.Bold)
                      }
                    }
                    .width('100%').height('100%')
                    .backgroundColor(this.cellBg(v, i))
                    .borderWidth(this.isCursorAt(i) ? (this.gridCols <= 4 ? 2 : this.gridCols <= 6 ? 1.5 : 1) : (v === 0 ? (this.gridCols <= 4 ? 0.5 : 0.3) : (this.gridCols <= 4 ? 1 : 0.5)))
                    .borderColor(this.isCursorAt(i) ? '#FF6B35' : (v === 0 ? '#2A2A4E' : '#FFFFFF44'))
                    .borderRadius(v > 0 ? (this.gridCols <= 4 ? 4 : 2) : 0)
                    .onClick(() => {
                      this.cursorX = i % this.gridCols;
                      this.cursorY = Math.floor(i / this.gridCols);
                      if (v > 0) { this.selectedId = v; playClick(); }
                      this.renderGrid();
                    })
                  }
                }, (i: number) => i.toString())
              }
              .columnsTemplate(repeatStr('1fr ', this.gridCols).trim())
              .rowsTemplate(repeatStr('1fr ', this.gridRows).trim())
              .columnsGap(this.gridCols <= 4 ? 1 : this.gridCols <= 6 ? 0.5 : 0.3)
              .rowsGap(this.gridCols <= 4 ? 1 : this.gridCols <= 6 ? 0.5 : 0.3)
              .width('92%').aspectRatio(this.gridCols / this.gridRows).alignSelf(ItemAlign.Center)

              // Win overlay
              if (this.showOverlay) {
                Column() {
                  Text('第' + this.level.toString() + '关 通关!').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFD700')
                  Text('步数: ' + this.moves.toString()).fontSize(18).fontColor('#FFFFFF').margin({ top: 6 })
                  Row() {
                    Button() { Text('重试').fontSize(13).fontColor('#F9F6F2') }
                    .backgroundColor('#8F7A66').borderRadius(6)
                    .onClick(() => { this.restartLevel(); })
                    Button() { Text('下一关').fontSize(13).fontColor('#F9F6F2') }
                    .backgroundColor('#CC4444').borderRadius(6).margin({ left: 12 })
                    .onClick(() => { this.nextLevel(); })
                  }
                  .margin({ top: 10 })
                }
                .width('100%').height('100%')
                .backgroundColor('#AA000000')
                .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).borderRadius(8)
              }
            }
            .width('92%').layoutWeight(1).alignSelf(ItemAlign.Center)
          }
          .width('100%').height(450).backgroundColor('#1A1A2E').borderRadius(8)
          .clip(true)
          .padding({ top: 10, bottom: 8, left: 12, right: 12 })
          .justifyContent(FlexAlign.Center)
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
      }
      }
      .width('92%').layoutWeight(1).constraintSize({ maxWidth: 540 }).backgroundColor('#D4D0C8').borderRadius(24)
    }
    .width('100%').height('100%').backgroundColor('#2B2B2B')
    .justifyContent(FlexAlign.Center).padding({ top: 40, bottom: 15 })
  }

  @Builder DPadLayout() {
    Stack() {
      Button() { Image($r('app.media.icon_up')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: -42 })
      .onClick(() => { this.moveCursor(0, -1); })
      Button() { Image($r('app.media.icon_down')).width(60).height(60) }
      .width(76).height(58).backgroundColor('transparent').borderRadius(0).offset({ y: 42 })
      .onClick(() => { this.moveCursor(0, 1); })
      Button() { Image($r('app.media.icon_left')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: -42 })
      .onClick(() => { this.moveCursor(-1, 0); })
      Button() { Image($r('app.media.icon_right')).width(60).height(60) }
      .width(58).height(76).backgroundColor('transparent').borderRadius(0).offset({ x: 42 })
      .onClick(() => { this.moveCursor(1, 0); })
    }
    .width(140).height(140)
  }

  @Builder StartSelectLayout() {
    Row() {
      Button() { Text('START').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#CC4444').borderRadius(14)
      .onClick(() => { this.restartLevel(); })
      Button() { Text('BACK').fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .width(64).height(28).backgroundColor('#4488CC').borderRadius(14).margin({ left: 16 })
      .onClick(() => {
        try { this.getUIContext().getRouter().back(); } catch (_) {}
      })
    }
  }

  @Builder ActionButtonLayout() {
    Row() {
      Stack() { Circle().width(56).height(56).fill('#4488CC'); Text('B').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .onClick(() => { this.pressB(); })
      Stack() { Circle().width(64).height(64).fill('#CC4444'); Text('A').fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold) }
      .margin({ left: 12 })
      .onClick(() => { this.pressA(); })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 0 })
    PageTransitionExit({ duration: 0 })
  }
}
