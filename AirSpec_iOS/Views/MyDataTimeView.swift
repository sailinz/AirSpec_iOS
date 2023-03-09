//
//  MyDataTimeView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 23.12.22.
//

import SwiftUI
import Charts
import InfluxDBSwift
import Foundation


private let sensorSettingList = SensorIconConstants.sensorThermal + SensorIconConstants.sensorAirQuality + SensorIconConstants.sensorVisual + SensorIconConstants.sensorAcoustics

struct MyDataTimeView: View {
  

    /// comfort
    @State var comfortDataIn = comfortData.today
    private let pointSize = 10.0
    private let showLegend = false

    /// environment
    private let lineWidth = 1.0
    private let interpolationMethod: ChartInterpolationMethod = .cardinal
    private let chartColor: Color = .pink
    private let showSymbols = true

    private let showLollipop = true

    @State var data: [(minutes: Date, values: Double)] = []
    @State private var selectedElement: temp?

    @State var flags = Array(repeating: false, count: sensorSettingList.count)
    @State var user_id: String = ""
    
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        
//
        VStack(alignment: .leading){
//            Text("Comfort votes")
//                .font(.system(.caption).weight(.semibold))
//
//            chartComfort
//            Text("Sensor readings")
//                .font(.system(.caption).weight(.semibold))
//            Spacer()
//                .frame(height: 100)
            HStack{
                Image(systemName: "info.circle")
                Text("About \(sensorSettingList[flags.firstIndex(where: { $0 }) ?? 0].name.replacingOccurrences(of: "\n", with: " "))")
                    .font(.system(size: 22) .weight(.heavy))
            }
            .padding()
            
            
            chartEnv
                .padding()


            LazyVGrid(columns: columns, spacing: 18){
                ForEach(flags.indices) { j in
                    VStack{
                        ToggleItem(storage: self.$flags, user_id: self.$user_id, data: self.$data, checkTogglekImage: sensorSettingList[j].icon, checkToggleText:sensorSettingList[j].name, tag: j, label: "")

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
                .symbolSize(pointSize * 1.8)
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
            BarMark(
                x: .value("Date", $0.minutes),
                y: .value("values", $0.values),
                width:2
            )
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .foregroundStyle(chartColor.gradient)
            .cornerRadius(5)
//            LineMark(
//                x: .value("Date", $0.minutes),
//                y: .value("values", $0.values)
//            )
//            .lineStyle(StrokeStyle(lineWidth: lineWidth))
//            .foregroundStyle(chartColor.gradient)
//            .interpolationMethod(interpolationMethod.mode)
//            .symbol(Circle().strokeBorder(lineWidth: lineWidth))
//            .symbolSize(showSymbols ? 10 : 0)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let element = findElement(location: value.location, proxy: proxy, geometry: geo)
                                if selectedElement?.minutes == element?.minutes {
                                    /// If tapping the same element, clear the selection.
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
                        .offset(x: boxOffset, y:-50)
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
        let mappedData = data.map {temp(minutes: $0.minutes, values: Int($0.values)) }
        if let date = proxy.value(atX: relativeXPosition) as Date? {
            /// Find the closest date element.
            var minDistance: TimeInterval = .infinity
            var index: Int? = nil
            for valuesDataIndex in mappedData.indices {
                let nthvaluesDataDistance = data[valuesDataIndex].minutes.distance(to: date)
                if abs(nthvaluesDataDistance) < minDistance {
                    minDistance = abs(nthvaluesDataDistance)
                    index = valuesDataIndex
                }
            }
            if let index {
                return mappedData[index]
            }
        }
        return nil
    }
}

struct ToggleItem: View {
    @Binding var storage: [Bool]
    @Binding var user_id: String
    @Binding var data: [(minutes: Date, values: Double)]

    var checkTogglekImage:String
    var checkToggleText:String
    var tag: Int
    var label: String = ""

    var body: some View {
        let isOn = Binding (get: { self.storage[self.tag] },
            set: { value in
                withAnimation {
                    self.storage = self.storage.enumerated().map { $0.0 == self.tag }
                }
            })


        if(self.storage[self.tag]){
            
            startQueries(i:self.tag)

        }
        return Toggle(label, isOn: isOn)
                .toggleStyle(CheckToggleStyle(checkTogglekImage: checkTogglekImage, checkToggleText: checkToggleText))
    }

    func startQueries(i:Int) {
        do {
            let (longTermData, onComplete) = try LongTermDataViewModel.fetchData()
            if longTermData.isEmpty {
                print("no long term data")
//                try onComplete()
                return
            }
            
            var err: Error?

            
            let selectedSensorData = longTermData.filter { $0.1 == sensorSettingList[i].name}
            
            
            let convertedSensorData = selectedSensorData.compactMap { tuple -> (Date, Double)? in
                let date = tuple.0
                let dateString = "\(date)"
                let valuesString = "\(tuple.2)"
                return convertToData(dateString: dateString, valuesString: valuesString)
            }

            if convertedSensorData.isEmpty {
                print("No matching tuples found")
            } else {
                DispatchQueue.main.async {
                    self.data = convertedSensorData
                    
                }
                
            }
            
            if let err = err {
                throw err
            } else {
                try onComplete()
            }
        } catch {
            print("no long term data: \(error)")
        }
        
    }

}

func convertToData(dateString: String, valuesString: String) -> (minutes: Date, values: Double)? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

    if let date = dateFormatter.date(from: dateString), let values = Double(valuesString) {
        return (minutes: date, values: values)
    } else {
        return nil
    }
}

struct CheckToggleStyle: ToggleStyle {
    var checkTogglekImage:String
    var checkToggleText:String
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            }
            icon: {
                VStack{
                    Image(systemName: checkTogglekImage)
                        .font(.system(size: 22))
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .imageScale(.large)
                        .frame(width: 30, height: 30)

                    Text(checkToggleText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .font(configuration.isOn ? (.system(size: 13) .weight(.semibold)) : (.system(size: 12).weight(.regular)))
                }
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
