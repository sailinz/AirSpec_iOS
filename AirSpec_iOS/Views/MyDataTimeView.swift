//
//  MyDataTimeView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 23.12.22.
//

import SwiftUI
import Charts

struct MyDataTimeView: View {

    /// comfort
    @State var comfortDataIn = comfortData.today
    @State private var pointSize = 10.0
    @State private var showLegend = false
    
    /// environment
    @State private var lineWidth = 1.0
    @State private var interpolationMethod: ChartInterpolationMethod = .cardinal
    @State private var chartColor: Color = .gray
    @State private var showSymbols = true
    @State private var selectedElement: temp? = TempData.last30minutes[10]
    @State private var showLollipop = true
    var data = TempData.last30minutes
    
    @State private var toggleImage: Image = Image(systemName: "circle")
    @State private var isOn = false
    @State var flags = Array(repeating: false, count: 8)
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Comfort vote")
                .font(.system(.caption) .weight(.semibold))
            chartComfort
            chartEnv
            Text("Sensing data")
                .font(.system(.caption) .weight(.semibold))
//            Toggle("", isOn: $isOn)
//                .toggleStyle(CheckToggleStyle(checkTogglekImage: SensorIconConstants.sensorThermal[0].icon))
            LazyVGrid(columns: columns, spacing: 0){
                let sensorSettingList = [SensorIconConstants.sensorThermal[0],SensorIconConstants.sensorThermal[1], SensorIconConstants.sensorAirQuality[0],SensorIconConstants.sensorAirQuality[1],SensorIconConstants.sensorAirQuality[2],SensorIconConstants.sensorAirQuality[3],SensorIconConstants.sensorVisual[0], SensorIconConstants.sensorAcoustics[0]]
                ForEach(flags.indices) { j in
                    VStack{
                        ToggleItem(storage: self.$flags, checkTogglekImage: sensorSettingList[j].icon, tag: j, label: "")
                            .padding(.horizontal)
                        Text(sensorSettingList[j].name)
                            .font(.system(.caption2))
                    }
                    
                }
            }.padding()
            
            
            
        }
    }
    
    private var chartComfort: some View {
        Chart {
            ForEach(comfortDataIn) { series in
                ForEach(series.value, id: \.minutes) { element in
                    PointMark(
                        x: .value("Minute", element.minutes),
                        y: .value("Value", element.value)
                    )
                }
                .foregroundStyle(by: .value("Comfort status", series.comfortType))
                .symbol(by: .value("Comfort status", series.comfortType))
                .symbolSize(pointSize * 2)
            }
        }
        .chartLegend(.hidden)
        .chartLegend(position: .bottomLeading)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(height:Constants.previewChartHeight)
        .chartForegroundStyleScale([
            "comfy": .mint,
            "not comfy": .pink
        ])
        .chartSymbolScale([
            "comfy": Circle().strokeBorder(lineWidth: lineWidth),
            "not comfy": Circle().strokeBorder(lineWidth: lineWidth)
        ])
    }
    
    private var chartEnv: some View {
        Chart(data, id: \.minutes) {
//            BarMark(
//                x: .value("Date", $0.minutes),
//                y: .value("values", $0.values),
//                width:5
//            )
//            .lineStyle(StrokeStyle(lineWidth: lineWidth))
//            .foregroundStyle(chartColor.gradient)
//            .cornerRadius(10)
            LineMark(
                x: .value("Date", $0.minutes),
                y: .value("values", $0.values)
            )
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .foregroundStyle(chartColor.gradient)
            .interpolationMethod(interpolationMethod.mode)
            .symbol(Circle().strokeBorder(lineWidth: lineWidth))
            .symbolSize(showSymbols ? 60 : 0)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let element = findElement(location: value.location, proxy: proxy, geometry: geo)
                                if selectedElement?.minutes == element?.minutes {
                                    // If tapping the same element, clear the selection.
                                    selectedElement = nil
                                } else {
                                    selectedElement = element
                                }
                            }
                            .exclusively(
                                before: DragGesture()
                                    .onChanged { value in
                                        selectedElement = findElement(location: value.location, proxy: proxy, geometry: geo)
                                    }
                            )
                    )
            }
        }
        .chartBackground { proxy in
            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    if showLollipop,
                       let selectedElement {
                        let dateInterval = Calendar.current.dateInterval(of: .minute, for: selectedElement.minutes)!
                        let startPositionX1 = proxy.position(forX: dateInterval.start) ?? 0

                        let lineX = startPositionX1 + geo[proxy.plotAreaFrame].origin.x
                        let lineHeight = geo[proxy.plotAreaFrame].maxY
                        let boxWidth: CGFloat = 50
                        let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))

                        Rectangle()
                            .fill(.black)
                            .frame(width: 2, height: lineHeight)
                            .position(x: lineX, y: lineHeight / 2)

                        VStack(alignment: .center) {
                            Text("\(selectedElement.minutes, format: .dateTime.hour().minute())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(selectedElement.values, format: .number)")
                                .font(.body.bold())
                                .foregroundColor(.primary)
                        }
                        .frame(width: boxWidth, alignment: .leading)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.background)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary.opacity(0.7))
                            }
                            .padding(.horizontal, -8)
                            .padding(.vertical, -4)
                        }
                        .offset(x: boxOffset)
                    }
                }
            }
        }
        .chartXAxis(.automatic)
        .chartYAxis(.hidden)
        .frame(height: Constants.detailChartHeight) /// :Constants.detailChartHeight
    }

    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> temp? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        if let date = proxy.value(atX: relativeXPosition) as Date? {
            // Find the closest date element.
            var minDistance: TimeInterval = .infinity
            var index: Int? = nil
            for valuesDataIndex in data.indices {
                let nthvaluesDataDistance = data[valuesDataIndex].minutes.distance(to: date)
                if abs(nthvaluesDataDistance) < minDistance {
                    minDistance = abs(nthvaluesDataDistance)
                    index = valuesDataIndex
                }
            }
            if let index {
                return data[index]
            }
        }
        return nil
    }
}

struct ToggleItem: View {
    @Binding var storage: [Bool]
    var checkTogglekImage:String
    var tag: Int
    var label: String = ""

    var body: some View {
        let isOn = Binding (get: { self.storage[self.tag] },
            set: { value in
                withAnimation {
                    self.storage = self.storage.enumerated().map { $0.0 == self.tag }
                }
            })
        return Toggle(label, isOn: isOn).toggleStyle(CheckToggleStyle(checkTogglekImage: checkTogglekImage))
    }
}


struct CheckToggleStyle: ToggleStyle {
    var checkTogglekImage:String
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            }
            icon: {
                Image(systemName: checkTogglekImage)
                    .foregroundColor(configuration.isOn ? .black : .gray)
                    .imageScale(.large)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct MyDataTimeView_Previews: PreviewProvider {
    static var previews: some View {
        MyDataTimeView()
    }
}
