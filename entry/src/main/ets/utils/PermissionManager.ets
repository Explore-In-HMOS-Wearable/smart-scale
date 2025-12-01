import { abilityAccessCtrl, Permissions, bundleManager, PermissionRequestResult, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { getGlobalContext } from '../entryability/EntryAbility';

export class PermissionManager {
  private context: common.UIAbilityContext = getGlobalContext();

  requestPermissions(): void {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context, ['ohos.permission.ACCESS_BLUETOOTH'])
      .then((data: PermissionRequestResult) => {
        this.checkPermissionsAfterRequest();
      })
      .catch((err: BusinessError) => {
       });
  }

  async checkPermissionsAfterRequest() {
    const permissions: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH'];
    let allGranted = true;

    for (let permission of permissions) {
      let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permission);
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        allGranted = false;
        break;
      }
    }
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      let tokenId: number = appInfo.accessTokenId;

      grantStatus = await atManager.checkAccessToken(tokenId, permission);
      return grantStatus;
    } catch (error) {
      return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
  }
}