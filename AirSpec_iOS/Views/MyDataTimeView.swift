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
            VStack{
                HStack{
                    Image(systemName: "info.circle")
                    Text("About \(sensorSettingList[flags.firstIndex(where: { $0 }) ?? 0].name.replacingOccurrences(of: "\n", with: " "))")
                        .font(.system(size: 22) .weight(.heavy))
                }
                Text(sensorSettingList[flags.firstIndex(where: { $0 }) ?? 0].meaning)
                    .font(.system(size: 12) .weight(.light))
                    .fixedSize(horizontal: false, vertical: false)
            }
            .padding(.horizontal)
            
            Spacer()
            ZStack{
                HStack(alignment: .center){
                    Spacer()
                    Text("All days")
                        .font(.system(.subheadline) .weight(.semibold))
                    /// Toggle credit: https://toddhamilton.medium.com/prototype-a-custom-toggle-in-swiftui-d324941dac40
                    ZStack {
                        Capsule()
                            .frame(width:66,height:30)
                            .foregroundColor(Color(isTodayData ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1028798084) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6039008336)))
                        ZStack{
                            Circle()
                                .frame(width:26, height:26)
                                .foregroundColor(.white)
                            Image(systemName: isTodayData ? "clock.arrow.circlepath" : "calendar")
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
            chartEnv
                .padding(.horizontal)
            

            LazyVGrid(columns: columns, spacing: 8){
                ForEach(flags.indices) { j in
                    VStack{
                        ToggleItem(storage: self.$flags, isTodayData: self.$isTodayData, data: self.$data, checkTogglekImage: sensorSettingList[j].icon, checkToggleText:sensorSettingList[j].name, tag: j, label: "")

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

        }
        .chartXAxis(.automatic)
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
                let convertedSensorData = selectedSensorData.compactMap { tuple -> (Date, Double)? in
                    
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
                let convertedSensorData = selectedSensorData.compactMap { tuple -> (Date, Double)? in
                    
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
    static var previews: some View {
        MyDataTimeView()
    }
}
