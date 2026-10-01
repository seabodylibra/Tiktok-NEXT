import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/Index')
        .then(() => {
          const mainWindow = windowStage.getMainWindowSync();
          return mainWindow.setWindowSystemBarProperties({
            statusBarColor: '#111114',
            navigationBarColor: '#111114',
            statusBarContentColor: '#F5F5F7',
            navigationBarContentColor: '#F5F5F7'
          });
        })
        .catch(() => {
          console.error('Unable to initialize the page or system bar appearance.');
        });
    } catch {
      console.error('Unable to initialize the application window.');
    }
  }
}