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


private let sensorSettingList = [SensorIconConstants.sensorThermal[0],SensorIconConstants.sensorThermal[1], SensorIconConstants.sensorAirQuality[0],SensorIconConstants.sensorAirQuality[1],SensorIconConstants.sensorAirQuality[2],SensorIconConstants.sensorAirQuality[3],SensorIconConstants.sensorVisual[0], SensorIconConstants.sensorAcoustics[0]]

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
//    var data = TempData.last30minutes
    @State var data: [(minutes: Date, values: Double)] = []
    @State private var selectedElement: temp?
    
//    @State private var toggleImage: Image = Image(systemName: "circle")
//    @State private var isOn = false
    @State var flags = Array(repeating: false, count: 8)
    @State var user_id:String = "9067133"
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(alignment: .center){
            Text("Comfort votes")
                .font(.system(.caption).weight(.semibold))
            
            chartComfort
            Text("Sensor readings")
                .font(.system(.caption).weight(.semibold))
            Spacer()
                .frame(height: 60)
            chartEnv
            
            
                
//            Toggle("", isOn: $isOn)
//                .toggleStyle(CheckToggleStyle(checkTogglekImage: SensorIconConstants.sensorThermal[0].icon))
            LazyVGrid(columns: columns, spacing: 20){
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
            .symbolSize(showSymbols ? 10 : 0)
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
            // Find the closest date element.
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
//    var lastTag: Int
    var label: String = ""
    
    let influxClient = try InfluxDBClient(url: NetworkConstants.url, token: NetworkConstants.token)
    
//    mutating func updateLastTag() {
//        self.lastTag = self.tag
//    }
    
    var body: some View {
        let isOn = Binding (get: { self.storage[self.tag] },
            set: { value in
                withAnimation {
                    self.storage = self.storage.enumerated().map { $0.0 == self.tag }
                }
            })
        
        
        if(self.storage[self.tag]){
            print(self.tag)
//            print(storage)
            
            startQueries(i:self.tag)
            
        }
        return Toggle(label, isOn: isOn)
                .toggleStyle(CheckToggleStyle(checkTogglekImage: checkTogglekImage, checkToggleText: checkToggleText))
    }
    
    func startQueries(i:Int) {
        
        /// environmental sensing
//        DispatchQueue.global().async {
        var tempData: [(minutes: Date, values: Double)] = []
        var query = """
                    """
        if(i == 6){ ///lux has no type
            query = """
                            from(bucket: "\(NetworkConstants.bucket)")
                            |> range(start: -1h)
                            |> filter(fn: (r) => r["_measurement"] == "\(sensorSettingList[i].measurement)")
                            |> filter(fn: (r) => r["_field"] == "signal")
                            |> filter(fn: (r) => r["id"] == "\(user_id)")
                            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
                    """
        }else{
            query = """
                            from(bucket: "\(NetworkConstants.bucket)")
                            |> range(start: -30m)
                            |> filter(fn: (r) => r["_measurement"] == "\(sensorSettingList[i].measurement)")
                            |> filter(fn: (r) => r["_field"] == "signal")
                            |> filter(fn: (r) => r["id"] == "\(user_id)")
                            |> filter(fn: (r) => r["\(sensorSettingList[i].identifier)"] == "\(sensorSettingList[i].type)")
                            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
                    """
        }
        
        influxClient.queryAPI.query(query: query, org: NetworkConstants.org) {response, error in
            // Error response
            if let error = error {
                print("Error:\n\n\(error)")
            }
            
            // Success response
            if let response = response {
                
                print("\nSuccess response...\n")
                do {
                    try response.forEach { record in
//                            DispatchQueue.main.async {
//                                print(record.values["_time"]!)
//                                print(record.values["_value"]!)
                        if let result = convertToData(dateString: "\(record.values["_time"]!)", valuesString: "\(record.values["_value"]!)") {
                            tempData.append(result)
                        }
//                            }
                        
                    }
                    self.data = tempData
//                        print(tempData)
//                        print(self.data)
                } catch {
                    print("Error:\n\n\(error)")
                }
            }
            
        }
            
            

//        }
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
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .imageScale(.large)
                        .frame(width: 30, height: 30)
                    
                    Text(checkToggleText)
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .font(configuration.isOn ? (.system(size: 10) .weight(.semibold)) : (.system(size: 8).weight(.regular)))
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
