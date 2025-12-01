import { McLineChart, Options } from '@mcui/mccharts'
import RdbService from '../utils/RdbService';

@Builder
export function WeightChartBuilder() {
  WeightChart()
}

@Entry
@Component
struct WeightChart {
  pageStack: NavPathStack = new NavPathStack();
  @State seriesOption: Options = new Options({
    xAxis: {
      data: [],
      axisLabel: {
        color: '#333',
        fontWeight: '500',
        fontSize: 40
      },
    },
    yAxis: {
      axisLabel: {
        color: '#333',
        fontWeight: '500',
        fontSize: 40
      }
    },
    series: [
      { name: 'Weight' }
    ]
  })

  async aboutToAppear() {
    const data = await RdbService.getLimitedRecord(10);
    const weightValues: number[] = data.map(item => item.WEIGHT);

    this.seriesOption.setVal({
      series: [
        {
          name: 'Weight',
          data: weightValues
        }
      ],
      xAxis: {
        data: weightValues
      },
      yAxis: {
        data: weightValues
      }
    })

  }

  build() {
    NavDestination() {
      McLineChart({
        options: this.seriesOption
      })
        .height('80%')
        .width('80%')
        .padding(16)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack;
    })
  }
}