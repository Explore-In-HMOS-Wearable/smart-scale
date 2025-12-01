import { PermissionManager } from '../utils/PermissionManager';
import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import RdbService from '../utils/RdbService';


let currentValue: string = '0.00';
let btName: string = 'MI SCALE2';
let deviceId: string = '';
let device: ble.GattClientDevice;
let services: Array<ble.GattService>;
let onWeightChange: (val: string, isStable: boolean) => void;
let onConnectionChange: (val: boolean) => void;
let startBlinking: (val: boolean) => void;
const MAX_WEIGHT: number = 150;

function ConnectStateChanged(state: ble.BLEConnectionChangeState) {
  if (state.state === constant.ProfileConnectionState.STATE_CONNECTED) {
    onConnectionChange(true)
    device.getServices(getServices);
  }
}

let getServices = (code: BusinessError, gattServices: Array<ble.GattService>) => {
  if (code && code.code != 0) {
    return;
  }
  services = gattServices;
  getWeight()
}

function getWeight() {
  for (const service of services) {
    // 181D → Weight Scale Service UUID
    if (service.serviceUuid.includes('181D')) {
      for (const characteristic of service.characteristics) {
        // 2A9D → Weight Measurement Characteristic UUID
        if (characteristic.characteristicUuid.includes('2A9D')) {
          device.setCharacteristicChangeIndication(characteristic, true);
        }
      }
    }
  }
}

function parseWeight(data: Uint8Array): string {
  const isStable = data[0] === 34;
  const weightRaw = data[1] | (data[2] << 8);
  const weight = weightRaw / 200.0;
  onWeightChange && onWeightChange(weight.toFixed(2), isStable);
  if (isStable) {
    startBlinking(true)
  }
  return weight.toFixed(2)
}

function CharacteristicChange(characteristicChangeReq: ble.BLECharacteristic) {
  let value: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);
  currentValue = parseWeight(value);
}

@Builder
export function MainBuilder() {
  Main()
}

async function onReceiveEvent(data: Array<ble.ScanResult>) {
  if (data[0].deviceName === btName) {
    deviceId = data[0].deviceId;
    ble.stopBLEScan()

    try {
      device = ble.createGattClientDevice(deviceId)
      device.on('BLEConnectionStateChange', ConnectStateChanged);
      device.on('BLECharacteristicChange', CharacteristicChange);
      device.connect();
    } catch (err) {
     }
  }
}

@Entry
@Component
struct Main {
  private permissionManager = new PermissionManager();
  pageStack: NavPathStack = new NavPathStack();
  @State isConnected: boolean = false;
  @State isStable: boolean = false;
  @State weight: string = '0.00';
  @State isBlinking: boolean = false;
  @State blinkInterval: number | null = null;
  @State blinkTimeout: number | null = null;
  @State showText: boolean = true;
  @State lastWeight: number = 0;

  async aboutToAppear(): Promise<void> {
    this.permissionManager.requestPermissions();
    onConnectionChange = (isConnected: boolean) => {
      this.isConnected = isConnected;
    }
    onWeightChange = async (val: string, isStable: boolean) => {
      this.weight = val;
      this.isStable = isStable;
      if (this.isStable) {
        await RdbService.insertWeightData(Number(val));
      }
    };
    startBlinking = (val: boolean) => {
      if (val) {
        this.startBlinking()
      }
    }
  }

  searchDevice() {
    try {
      ble.on('BLEDeviceFind', onReceiveEvent);

      let scanOptions: ble.ScanOptions = {
        interval: 500,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      }
      ble.startBLEScan(null, scanOptions);
    } catch (err) {
    }
  }

  startBlinking() {
    if (this.isBlinking) {
      return;
    }

    this.isBlinking = true;

    this.blinkInterval = setInterval(() => {
      this.showText = !this.showText;
    }, 300);

    this.blinkTimeout = setTimeout(() => {
      this.stopBlinking();
    }, 2000);
  }

  stopBlinking() {
    if (this.blinkInterval) {
      clearInterval(this.blinkInterval);
    }
    if (this.blinkTimeout) {
      clearTimeout(this.blinkTimeout);
    }

    this.blinkInterval = null;
    this.blinkTimeout = null;
    this.isBlinking = false;
    this.showText = true;
  }

  build() {
    Navigation(this.pageStack) {
      LoadingProgress()
        .enableLoading(!this.isConnected)
        .width(150)
        .visibility(this.isConnected ? Visibility.None : Visibility.Visible)
      Text('Connecting')
        .onClick(async () => {
          await RdbService.insertWeightData(Math.random() * 150 + 1);
          const record = await RdbService.getLimitedRecord();
          this.pageStack.pushPath({
            name: 'Records'
          })
        })
        .visibility(this.isConnected ? Visibility.None : Visibility.Visible);
      if (this.isConnected) {
        Stack() {

          Column({ space: 8 }) {
            Text(`${this.weight} kg`)
              .opacity(this.showText ? 1 : 0)
              .fontSize(24)

            Button('Records')
              .onClick(() => {
                this.pageStack.pushPath({ name: 'Records' })
              })
          }
          .zIndex(10)

          Progress({
            value: Number(this.weight),
            total: MAX_WEIGHT,
            type: ProgressType.ScaleRing
          })
            .size({ width: '100%', height: '100%' })
            .style({
              enableSmoothEffect: false,
              strokeWidth: 20,
              scaleCount: 150
            })
            .zIndex(1)
        }

      }

    }
    .onAppear(() => {
      this.searchDevice()
    })
    .hideTitleBar(true)
    .alignSelf(ItemAlign.Center)
    .width('100%')
    .height('100%')
  }
}