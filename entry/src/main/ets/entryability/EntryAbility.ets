import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;

  private updateSafeArea = (): void => {
    const mainWindow = this.mainWindow;
    if (!mainWindow) { return; }
    try {
      const system = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const cutout = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      AppStorage.setOrCreate('windowTopInset', mainWindow.getUIContext().px2vp(
        Math.max(system.topRect.height, cutout.topRect.height)));
    } catch { console.warn('Unable to read the window safe area.'); }
  };

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
          this.mainWindow.on('avoidAreaChange', this.updateSafeArea);
          return this.mainWindow.setWindowLayoutFullScreen(true).then(() => this.updateSafeArea());
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
    this.mainWindow?.off('avoidAreaChange', this.updateSafeArea);
    this.mainWindow = undefined;
  }
}