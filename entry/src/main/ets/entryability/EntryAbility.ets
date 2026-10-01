import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;

  private syncWindowTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    const mainWindow = this.mainWindow;
    if (!mainWindow) {
      return;
    }
    const isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    const background = isDark ? '#111114' : '#FFFFFF';
    const foreground = isDark ? '#F5F5F7' : '#161618';
    try {

      mainWindow.setWindowSystemBarProperties({
        statusBarColor: background,
        navigationBarColor: background,
        statusBarContentColor: foreground,
        navigationBarContentColor: foreground
      }).catch(() => {
        console.error('Unable to update the system bar appearance.');
      });
    } catch {
      console.error('Unable to update the window appearance.');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/Index')
        .then(() => {
          this.mainWindow = windowStage.getMainWindowSync();
          this.syncWindowTheme(this.context.config.colorMode);
        })
        .catch(() => {
          console.error('Unable to initialize the application page.');
        });
    } catch {
      console.error('Unable to initialize the application window.');
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    this.syncWindowTheme(newConfig.colorMode ?? this.context.config.colorMode);
  }

  onForeground(): void {
    this.syncWindowTheme(this.context.config.colorMode);
  }

  onWindowStageDestroy(): void {
    this.mainWindow = undefined;
  }
}