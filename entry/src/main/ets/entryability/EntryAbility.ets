import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;

  private syncWindowTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    const isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('systemDark', isDark);
    const mainWindow = this.mainWindow;
    if (!mainWindow) {
      return;
    }
    const background = isDark ? '#000000' : '#FFFFFF';
    const foreground = isDark ? '#F5F5F7' : '#161618';
    try {

      mainWindow.setWindowSystemBarProperties({
        statusBarColor: background,
        navigationBarColor: '#00000000',
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
    this.syncWindowTheme(this.context.config.colorMode);
    try {
      windowStage.loadContent('pages/Index')
        .then(() => {
          this.mainWindow = windowStage.getMainWindowSync();
          this.syncWindowTheme(this.context.config.colorMode);
          return this.mainWindow.setWindowLayoutFullScreen(true);
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