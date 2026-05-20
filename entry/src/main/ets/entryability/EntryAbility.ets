import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    try {
      let win = windowStage.getMainWindowSync();
      if (win) {
        win.setWindowLayoutFullScreen(true);
        win.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: '#FFFFFF',
          navigationBarContentColor: '#FFFFFF'
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Window config error: %{public}s', JSON.stringify(err));
    }

    PersistentStorage.persistProp('Best2048', 0);
    PersistentStorage.persistProp('BestMine', 0);
    PersistentStorage.persistProp('BestSnake', 0);
    PersistentStorage.persistProp('BestRacer', 0);
    PersistentStorage.persistProp('BestPlane', 0);
    PersistentStorage.persistProp('BestTetris', 0);
    PersistentStorage.persistProp('BestFlappy', 0);
    PersistentStorage.persistProp('BestGame1', 0);
    PersistentStorage.persistProp('BestGame2', 0);
    PersistentStorage.persistProp('BestGame3', 0);
    PersistentStorage.persistProp('BestGame4', 0);
    PersistentStorage.persistProp('BestGame5', 0);
    PersistentStorage.persistProp('BestGame6', 0);
    PersistentStorage.persistProp('BestGame7', 0);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
