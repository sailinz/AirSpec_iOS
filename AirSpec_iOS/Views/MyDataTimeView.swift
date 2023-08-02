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
//    private let interpolationMethod: ChartInterpolationMethod = .cardinal
    private let chartColor: Color = .pink
    private let showSymbols = true

    private let showLollipop = true

    @State var data: [(minutes: Date, values: Double)] = []
    @State private var selectedElement: temp?

    //@State var flags = Array(repeating: false, count: sensorSettingList.count)
    @Binding var flags: [Bool]
    @State var user_id: String = ""
    @State var isTodayData: Bool = true
    @State var isTodayDataToggled: Bool = false
    
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading){

            ZStack{
                HStack(alignment: .center){
                    Spacer()
                    Text("All days")
                        .font(.system(.subheadline) .weight(.semibold))
                    /// Toggle credit: https://toddhamilton.medium.com/prototype-a-custom-toggle-in-swiftui-d324941dac40
                    ZStack {
                        Capsule()
                            .frame(width:66,height:30)
                            .foregroundColor(isTodayData ? .pink.opacity(0.2) : .pink.opacity(0.7))
                        ZStack{
                            Circle()
                                .frame(width:26, height:26)
                                .foregroundColor(.white)
                            Image(systemName: isTodayData ? "clock.arrow.circlepath" : "calendar")
                                .foregroundColor(.pink)
                        }
                        .shadow(color: .black.opacity(0.14), radius: 4, x: 0, y: 2)
                        .offset(x:isTodayData ? 18 : -18)
                        .animation(.spring())
                    }
                    .onTapGesture {
                        
                        self.isTodayData.toggle()
                        UserDefaults.standard.set(true, forKey: "isTodayDataToggled")
                        RawDataViewModel.addMetaDataToRawData(payload: "Long term data of today is checked: \(self.isTodayData) (true: today; false: all days)", timestampUnix: Date(), type: 1)

                    }
                    Text("Today")
                        .font(.system(.subheadline) .weight(.semibold))
                    Spacer()
                }
                
                
            }
            .padding()
            
            chartEnv
                .padding()
            

            LazyVGrid(columns: columns, spacing: 8){
                ForEach(flags.indices) { j in
                    VStack{
                        ToggleItem(storage: self.$flags, isTodayData: self.$isTodayData, data: self.$data, checkTogglekImage: sensorSettingList[j].icon, checkToggleText:sensorSettingList[j].name, tag: j, label: "")

                    }

                }
            }.padding()
            
            Spacer()
            
            VStack{
                if flags.contains { $0 }{
                    HStack{
                        Image(systemName: "info.circle")
                        Text("About \(sensorSettingList[flags.firstIndex(where: { $0 }) ?? 0].name.replacingOccurrences(of: "\n", with: " "))")
                            .font(.system(size: 22) .weight(.heavy))
                    }
                    Text(sensorSettingList[flags.firstIndex(where: { $0 }) ?? 0].meaning)
                        .font(.system(.body) .weight(.light))
    //                    .fixedSize(horizontal: false, vertical: false)
                }
                
            }
            .padding()
            
            
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
        return Chart(data, id: \.minutes) {
            BarMark(
                x: .value("Date", $0.minutes),
                y: .value("values", $0.values),
                width:2
            )
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .foregroundStyle(chartColor.gradient)
            .cornerRadius(5)

        }
        .chartXAxis {
            if isTodayData {
                if data.count > 60{
                    AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                        if let date = value.as(Date.self) {
                            let hour = Calendar.current.component(.hour, from: date)
                            switch hour {
                                case 0, 12:
                                    AxisValueLabel(format: .dateTime.hour())
                                default:
                                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                                }
                            }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                }
                else{
                    AxisMarks(values: .automatic)
                }
            }else{
                if data.count > 100{
                    ///https://developer.apple.com/documentation/charts/customizing-axes-in-swift-charts?language=_2
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                        if let date = value.as(Date.self) {
                            let hour = Calendar.current.component(.hour, from: date)
                            AxisValueLabel {
                                VStack(alignment: .leading) {
                                    switch hour {
                                        case 0, 12:
                                            Text(date, format: .dateTime.hour())
                                        default:
                                            Text(date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                                        }
                                        if value.index == 0 || hour == 0 {
                                            Text(date, format: .dateTime.month().day())
                                        }
                                }
                            }

                            if hour == 0 {
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            } else {
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    }
                }else{
                    AxisMarks(values: .automatic)
                }

            }
            
        }
        .chartYAxis(.automatic)
        .frame(height: Constants.detailChartHeight)
        
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
    @Binding var isTodayData: Bool
    @Binding var data: [(minutes: Date, values: Double)]

    var checkTogglekImage:String
    var checkToggleText:String
    var tag: Int
    var label: String = ""
    

    var body: some View {
        let isOn = Binding (get: { self.storage[self.tag] },
            set: { value in
//                withAnimation {
                self.storage = self.storage.enumerated().map { $0.0 == self.tag }
//                }
            })


        if(self.storage[self.tag]){
            startQueries(i:self.tag)
            RawDataViewModel.addMetaDataToRawData(payload: "Long term data \(sensorSettingList[self.tag].name) is checked", timestampUnix: Date(), type: 1)

        }
        return Toggle(label, isOn: isOn)
                .toggleStyle(CheckToggleStyle(checkTogglekImage: checkTogglekImage, checkToggleText: checkToggleText))
    }

    func startQueries(i:Int) {
        let maxPoints = 48
        
        do {
            let (longTermData, onComplete) = try LongTermDataViewModel.fetchData()
            if longTermData.isEmpty {
                print("no long term data")
//                try onComplete()
                return
            }
            
            var err: Error?

            
            
            
            if(self.isTodayData){
                let calendar = Calendar.current
                let selectedSensorData = longTermData.filter { $0.1 == sensorSettingList[i].name && calendar.isDate($0.0, equalTo: Date(), toGranularity: .day)}
                var convertedSensorData = selectedSensorData.compactMap { tuple -> (Date, Double)? in
                    
                    let date = tuple.0
                    let dateString = "\(date)"
                    let valuesString = "\(tuple.2)"
                    
                    
                    return convertToData(dateString: dateString, valuesString: valuesString)
                }

                if convertedSensorData.isEmpty {
                    print("No matching tuples found")
                   
                    if !self.data.isEmpty {
                        DispatchQueue.main.async  {
                            self.data = []
                        }
                    }
                    
                        
                    
                } else {
                    
                    
                        
                    // Downsample the data to the maximum number of points
                    if convertedSensorData.count > maxPoints {
                        let strideStep = Int(convertedSensorData.count / maxPoints)
                        var downsampledData = [(minutes: Date, values: Double)]()
                        for i in stride(from: 0, to: convertedSensorData.count, by: strideStep) {
                            downsampledData.append(convertedSensorData[i])
                        }
                        convertedSensorData = downsampledData
                    }
                    
                    if(i != UserDefaults.standard.integer(forKey: "longTermDataSensor")){
                        print("queried data because of changed sensor")
                        var _ = true
                        UserDefaults.standard.set(self.tag, forKey: "longTermDataSensor")
                        DispatchQueue.main.async  {
                            self.data = convertedSensorData
                        }
                        
                    }
                    
                    
                    if UserDefaults.standard.bool(forKey: "isTodayDataToggled"){
                        print("queried data because of change time duration")
                        var _ = true
                        UserDefaults.standard.set(false, forKey: "isTodayDataToggled")
                        DispatchQueue.main.async  {
                            self.data = convertedSensorData
                        }
                        
                    }
                }
                
                if let err = err {
                    throw err
                } else {
                    try onComplete()
                }
            }else{
                let selectedSensorData = longTermData.filter { $0.1 == sensorSettingList[i].name}
                var convertedSensorData = selectedSensorData.compactMap { tuple -> (Date, Double)? in
                    
                    let date = tuple.0
                    let dateString = "\(date)"
                    let valuesString = "\(tuple.2)"
                    return convertToData(dateString: dateString, valuesString: valuesString)
                }

                if convertedSensorData.isEmpty {
                    print("No matching tuples found")
                    if !self.data.isEmpty {
                        DispatchQueue.main.async  {
                            self.data = []
                        }
                    }
                } else {
                    
                    // Downsample the data to the maximum number of points
                    if convertedSensorData.count > maxPoints {
                        let strideStep = Int(convertedSensorData.count / maxPoints)
                        var downsampledData = [(minutes: Date, values: Double)]()
                        for i in stride(from: 0, to: convertedSensorData.count, by: strideStep) {
                            downsampledData.append(convertedSensorData[i])
                        }
                        convertedSensorData = downsampledData
                    }
                    
                    if(i != UserDefaults.standard.integer(forKey: "longTermDataSensor")){
                        print("queried data because of changed sensor")
                        var _ = true
                        UserDefaults.standard.set(self.tag, forKey: "longTermDataSensor")
                        DispatchQueue.main.async  {
                            self.data = convertedSensorData
                        }
                    }
                    
                    
                    
                    
                    if UserDefaults.standard.bool(forKey: "isTodayDataToggled"){
                        print("queried data because of change time duration")
                        var _ = true
                        UserDefaults.standard.set(false, forKey: "isTodayDataToggled")
                        DispatchQueue.main.async  {
                            self.data = convertedSensorData
                        }
                    }
                    
                }
                
                if let err = err {
                    throw err
                } else {
                    try onComplete()
                }
            }
            
            
            
        } catch {
            print("no long term data: \(error)")
            RawDataViewModel.addMetaDataToRawData(payload: "no long term data: \(error)", timestampUnix: Date(), type: 2)
        }
        
    }

}

func formatLabel(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd, h a"
    return dateFormatter.string(from: date)
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
                        .font(.system(size: 20))
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .imageScale(.large)
                        .frame(width: 25, height: 25)

                    Text(checkToggleText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(configuration.isOn ? .pink : .gray)
                        .font(configuration.isOn ? (.system(size: 12) .weight(.semibold)) : (.system(size: 11).weight(.regular)))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct MyDataTimeView_Previews: PreviewProvider {
    struct MyDataTimeViewWrapper: View {

            @State var flags : [Bool] = Array(repeating: false, count: 12)
            var body: some View {
                MyDataTimeView(flags: $flags)
            }
        }
    static var previews: some View {
        MyDataTimeViewWrapper()
    }
}
