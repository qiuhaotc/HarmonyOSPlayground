import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PrivacyDialogComponent } from '../view/PrivacyDialogComponent';

const PREFERENCES_FILE_NAME: string = 'app_preferences';
const PREFERENCES_KEY_PRIVACY: string = 'isPrivacyAgreed';
const LAUNCHER_DELAY_TIME: number = 800;

/**
 * 应用启动页 - 负责首次启动时展示隐私协议弹窗
 */
@Entry
@Component
struct LauncherPage {
  private timerId: number = -1;
  private hasJumped: boolean = false;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyDialogComponent({
      cancel: () => {
        this.onCancel();
      },
      confirm: () => {
        this.onConfirm();
      }
    }),
    autoCancel: false,
    customStyle: true
  });

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  onPageShow(): void {
    this.getDataPreferences().then((prefs: preferences.Preferences) => {
      prefs.get(PREFERENCES_KEY_PRIVACY, false)
        .then((value: preferences.ValueType) => {
          if (value === true) {
            // 已同意过，直接跳转
            this.jumpToIndexPage();
          } else {
            // 未同意，弹出协议对话框
            this.dialogController.open();
          }
        })
        .catch((err: BusinessError) => {
          console.error('[LauncherPage] Get preferences value error: ' + JSON.stringify(err));
          this.dialogController.open();
        });
    }).catch((err: BusinessError) => {
      console.error('[LauncherPage] Get preferences error: ' + JSON.stringify(err));
      this.dialogController.open();
    });
  }

  getDataPreferences(): Promise<preferences.Preferences> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return preferences.getPreferences(context, PREFERENCES_FILE_NAME);
  }

  onCancel(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.terminateSelf();
    } catch (err) {
      console.error('[LauncherPage] Terminate self error: ' + JSON.stringify(err));
    }
  }

  onConfirm(): void {
    this.savePrivacyAgreed();
    this.jumpToIndexPage();
  }

  savePrivacyAgreed(): void {
    this.getDataPreferences().then((prefs: preferences.Preferences) => {
      prefs.put(PREFERENCES_KEY_PRIVACY, true).then(() => {
        prefs.flush();
      }).catch((err: BusinessError) => {
        console.error('[LauncherPage] Save privacy status error: ' + JSON.stringify(err));
      });
    }).catch((err: BusinessError) => {
      console.error('[LauncherPage] Get preferences error: ' + JSON.stringify(err));
    });
  }

  jumpToIndexPage(): void {
    if (this.hasJumped) {
      return;
    }
    this.hasJumped = true;
    this.timerId = setTimeout(() => {
      this.getUIContext().getRouter().replaceUrl({
        url: 'pages/Index'
      }).catch((error: Error) => {
        console.error('[LauncherPage] Jump to index error: ' + JSON.stringify(error));
      });
    }, LAUNCHER_DELAY_TIME);
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#FFF8E1', 0.0],
            ['#FFE082', 1.0]
          ]
        })

      Column() {
        // App图标
        Text('💰')
          .fontSize(96)
          .margin({ top: 160 })

        // 应用名称
        Text('轻松来记账')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#5D4037')
          .margin({ top: 24 })

        // 应用介绍
        Text('简单记账，清晰理财')
          .fontSize(16)
          .fontColor('#8D6E63')
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
