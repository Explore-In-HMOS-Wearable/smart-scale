import {
  ArcList,
  ArcListAttribute,
  ArcListItem,
  ArcListItemAttribute,
  ComponentContent,
  LengthMetrics
} from '@kit.ArkUI';
import { Weight } from '../model/WeightModel';
import RdbService from '../utils/RdbService';

@Builder
export function RecordsPageBuilder() {
  Records()
}

@Builder
function listHeader() {
  Column() {
    Text('History')
      .fontColor(Color.White)
      .fontSize('40px')
      .fontWeight(FontWeight.Bold)
  }.margin(16)
}

@Entry
@Component
struct Records {
  pageStack: NavPathStack = new NavPathStack();
  @State records: Array<Weight> = [];
  context: UIContext = this.getUIContext();
  header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(listHeader));

  async aboutToAppear(): Promise<void> {
    this.records = await RdbService.getAllData();
  }

  @Builder
  itemEnd(item: Weight) {
    Button({ type: ButtonType.Circle }) {
      Image($r('app.media.delete'))
        .width(32)
        .height(32)
    }
    .margin({
      right: 12
    })
    .backgroundColor(Color.Black)
    .onClick(() => {
      this.getUIContext()
        .animateTo({
          duration: 1000,
          curve: Curve.Smooth,
          iterations: 1,
          playMode: PlayMode.Normal,
        }, async () => {
          await RdbService.deleteDataById(item.ID);
          let index = this.records.indexOf(item)
          this.records.splice(index, 1);
        })
    })
  }

  build() {
    NavDestination() {
      ArcList({ initialIndex: 0, header: this.header }) {
        ForEach(this.records, (item: Weight) => {
          ArcListItem() {
            Row() {
              Text(`${item.WEIGHT} kg`)
                .textAlign(TextAlign.Center)
                .fontWeight(FontWeight.Bold)
                .fontSize('38px')
                .fontColor('#FFFFFFFF')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .borderRadius('65px')
          .width('410px')
          .height('130px')
          .backgroundColor('#26FFFFFF')
          .swipeAction({
            end: {
              builder: () => {
                this.itemEnd(item)
              }
            }
          })
        }, (item: Weight) => JSON.stringify(item))
        if (this.records.length === 0) {
          ArcListItem() {
            Text(`No records`)
              .fontSize('32px')
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold);
          }
        }
        if (this.records.length > 5) {
          ArcListItem() {
            Button('Show Weight Chart')
              .onClick(() => {
                this.pageStack.pushPath({
                  name: 'WeightChart'
                })
              })
          }
        }
      }
      .space(LengthMetrics.px(10))
      .width('466px')
      .height('466px')
      .borderRadius('233px')
      .backgroundColor(Color.Black);
    }
    .alignSelf(ItemAlign.Center)
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack;
    })
  }
}