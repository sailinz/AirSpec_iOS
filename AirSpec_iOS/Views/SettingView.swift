/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the watchOS app.
*/

import SwiftUI
//import UserNotifications

let sliderWidth = Float(UIScreen.main.bounds.width-140)

/// This view displays an interface for discovering and connecting to Bluetooth peripherals.
struct SettingView: View {
    
    @EnvironmentObject private var receiver: BluetoothReceiver
    @State var user_id:String = "" ///"9067133"
    @State private var togglePublicState = false
    @State private var toggleRangeState = false
    
    
    @State private var minValueTemp: Float = Float(SensorIconConstants.sensorThermal[0].color1Position) * sliderWidth
    @State private var maxValueTemp: Float = Float(SensorIconConstants.sensorThermal[0].color3Position) * sliderWidth
    @State private var minValueHum: Float = Float(SensorIconConstants.sensorThermal[1].color1Position) * sliderWidth
    @State private var maxValueHum: Float = Float(SensorIconConstants.sensorThermal[1].color3Position) * sliderWidth
    @State private var minValueLightIntensity: Float = Float(SensorIconConstants.sensorVisual[0].color1Position) * sliderWidth
    @State private var maxValueLightIntensity: Float = Float(SensorIconConstants.sensorVisual[0].color3Position) * sliderWidth
    @State private var minValueNoise: Float = Float(SensorIconConstants.sensorAcoustics[0].color1Position) * sliderWidth
    @State private var maxValueNoise: Float = Float(SensorIconConstants.sensorAcoustics[0].color3Position) * sliderWidth

    
    var body: some View {
        
        NavigationView{
            VStack{
//                Text("Settings")
//                    .font(
//                            .custom(
//                            "SF Pro Display",
//                            fixedSize: 30)
//                            .weight(.heavy)
//                        )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()
                
                VStack {
//                    Text("Glasses setting")
//                        .font(.system(.title2) .weight(.heavy))
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .onAppear{
//                            /// in the test mode
////                            toggleScanning()
////                            connectToAirSpec()
//                        }
                    
                    VStack(alignment: .leading) {
                        HStack() {
                            Image(systemName: "person.crop.circle.badge")
                                .frame(width: 30, height: 20)
                            Text("User ID")
                                .font(.system(.subheadline))
                            TextField("Enter ID", text: $user_id, onCommit: {
                                /// in production
                                toggleScanning()
                                connectToAirSpec()
                                    
                                })
                                .multilineTextAlignment(.trailing)
                                .font(.system(.subheadline))
                        }
                        
//                        Divider()
                        
                        HStack() {
                            Image(systemName: "eyeglasses")
                                .frame(width: 30, height: 20)
                            Text("AirSpec")
                                .font(.system(.subheadline))
                            
                            if let peripheral = receiver.connectedPeripheral {
                                if(peripheral.name!.contains("STM32WB") || peripheral.name!.contains("$user_id") || peripheral.name!.contains(receiver.GLASSNAME)){
                                    Text("Connected")
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.gray)
                                        .font(.system(.subheadline))
                                }else{
                                    Text("Disconnected")
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.gray)
                                        .font(.system(.subheadline))
                                }
                            }else{
                                Text("Disconnected")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(Color.gray)
                                    .font(.system(.subheadline))
                            }
                            
                        }
                        
//                        Divider()
                            
                        HStack() {
                            Image(systemName: "person.3.fill")
                                .frame(width: 30, height: 20)
                            Text("Public mode")
                                .font(.system(.subheadline))
                            Toggle(isOn: $togglePublicState) {
                                }
                                .buttonStyle(PlainButtonStyle())
                                .tint(.pink)
                                .alignmentGuide(.trailing) { _ in return -10 }
                        
                        }
                        
//                        Divider()
                            
                        HStack() {
                            Image(systemName: "heart.circle")
                                .frame(width: 30, height: 20)
                            Text("Range detection")
                                .font(.system(.subheadline))
                            Toggle(isOn: $toggleRangeState) {
                                }
                                .buttonStyle(PlainButtonStyle())
                                .tint(.pink)
                                .alignmentGuide(.trailing) { _ in return -10 }
                        
                        }
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
//                    .padding(.all, 10)
                    .background(Color.pink.opacity(0.05))
                    .cornerRadius(15)
                }
                .padding()
                
//                ZStack{
//                    List {
//                        Section(header: Text("Connected")) {
//                            connectedPeripheral
//                        }
//
//                        Section(header: Text("Datastream")){
//                            showData
//                        }
//                    }
//                }
                

                
                    VStack {
                        HStack{
                            Text("Comfort range")
                                .font(.system(.title2) .weight(.heavy))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                // Save the slider values to UserDefaults
                                UserDefaults.standard.set(self.minValueTemp/sliderWidth, forKey: "minValueTemp")
                                UserDefaults.standard.set(self.maxValueTemp/sliderWidth, forKey: "maxValueTemp")
                                UserDefaults.standard.set(self.minValueHum/sliderWidth, forKey: "minValueHum")
                                UserDefaults.standard.set(self.maxValueHum/sliderWidth, forKey: "maxValueHum")
                                UserDefaults.standard.set(self.minValueLightIntensity/sliderWidth, forKey: "minValueLightIntensity")
                                UserDefaults.standard.set(self.maxValueLightIntensity/sliderWidth, forKey: "maxValueLightIntensity")
                                UserDefaults.standard.set(self.minValueNoise/sliderWidth, forKey: "minValueNoise")
                                UserDefaults.standard.set(self.maxValueNoise/sliderWidth, forKey: "maxValueNoise")
                                print("\(self.minValueTemp/sliderWidth)")
                            }) {
                                Text("Update")
                                    .foregroundColor(.black)
                                    .font(.system(.subheadline) .weight(.semibold))
                            }
                            .padding(.all,8)
                            .background(.pink.opacity(0.05))
                            .clipShape(Capsule())

                        }
                        
                        
                        
                        VStack(alignment: .leading) {
                            ScrollView {
                            
                                Text("Temperature")
                                    .font(.system(.subheadline) .weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Image(systemName: SensorIconConstants.sensorThermal[0].icon)
                                        .frame(width: 30, height: 20)
                                    
                                    RRRangeSliderSwiftUI(
                                        minValue: self.$minValueTemp, // mimimum value
                                        maxValue: self.$maxValueTemp, // maximum value
    //                                    minLabel: "0", // mimimum Label text
    //                                    maxLabel: "100", // maximum Label text
                                        minLabelBound: Float(SensorIconConstants.sensorThermal[0].minValue),
                                        maxLabelBound: Float(SensorIconConstants.sensorThermal[0].maxValue),
                                        sliderWidth: sliderWidth, // set slider width
                                        sliderHeight: CGFloat(30.0),
                                        //                            backgroundTrackColor: Color.pink.opacity(0.5), // track color
                                        leftTrackColor:SensorIconConstants.sensorThermal[0].color1,
                                        rightTrackColor:SensorIconConstants.sensorThermal[0].color3,
                                        selectedTrackColor: SensorIconConstants.sensorThermal[0].color2, // track color
                                        globeColor: SensorIconConstants.sensorThermal[0].color2, // globe background color
                                        globeBackgroundColor: Color.white, // globe rounded border color
                                        sliderMinMaxValuesColor: Color.black // all text label color
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    Text(SensorIconConstants.sensorThermal[0].unit)
                                        .font(.system(.subheadline))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.black)
                                    
                                }
                                
                                Text("Humidity")
                                    .font(.system(.subheadline) .weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Image(systemName: SensorIconConstants.sensorThermal[1].icon)
                                        .frame(width: 30, height: 20)
                                    
                                    RRRangeSliderSwiftUI(
                                        minValue: self.$minValueHum, // mimimum value
                                        maxValue: self.$maxValueHum, // maximum value
    //                                    minLabel: "0", // mimimum Label text
    //                                    maxLabel: "100", // maximum Label text
                                        minLabelBound: Float(SensorIconConstants.sensorThermal[1].minValue),
                                        maxLabelBound: Float(SensorIconConstants.sensorThermal[1].maxValue),
                                        sliderWidth: sliderWidth, // set slider width
                                        sliderHeight: CGFloat(30.0),
                                        //                            backgroundTrackColor: Color.pink.opacity(0.5), // track color
                                        leftTrackColor:SensorIconConstants.sensorThermal[1].color1,
                                        rightTrackColor:SensorIconConstants.sensorThermal[1].color3,
                                        selectedTrackColor: SensorIconConstants.sensorThermal[1].color2, // track color
                                        globeColor: SensorIconConstants.sensorThermal[1].color2, // globe background color
                                        globeBackgroundColor: Color.white, // globe rounded border color
                                        sliderMinMaxValuesColor: Color.black // all text label color
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    Text(SensorIconConstants.sensorThermal[1].unit)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.black)
                                        .font(.system(.subheadline))
                                    
                                }
                                
                                
                                Text("Light intensity")
                                    .font(.system(.subheadline) .weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Image(systemName: SensorIconConstants.sensorVisual[0].icon)
                                        .frame(width: 30, height: 20)
                                    
                                    RRRangeSliderSwiftUI(
                                        minValue: self.$minValueLightIntensity, // mimimum value
                                        maxValue: self.$maxValueLightIntensity, // maximum value
    //                                    minLabel: "0", // mimimum Label text
    //                                    maxLabel: "100", // maximum Label text
                                        minLabelBound: Float(SensorIconConstants.sensorVisual[0].minValue),
                                        maxLabelBound: Float(SensorIconConstants.sensorVisual[0].maxValue),
                                        sliderWidth: sliderWidth, // set slider width
                                        sliderHeight: CGFloat(30.0),
                                        //                            backgroundTrackColor: Color.pink.opacity(0.5), // track color
                                        leftTrackColor:SensorIconConstants.sensorVisual[0].color1,
                                        rightTrackColor:SensorIconConstants.sensorVisual[0].color3,
                                        selectedTrackColor: SensorIconConstants.sensorVisual[0].color2, // track color
                                        globeColor: SensorIconConstants.sensorVisual[0].color2, // globe background color
                                        globeBackgroundColor: Color.white, // globe rounded border color
                                        sliderMinMaxValuesColor: Color.black // all text label color
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    Text(SensorIconConstants.sensorVisual[0].unit)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.black)
                                        .font(.system(.subheadline))
                                    
                                }
                                
                                
                                Text("Noise")
                                    .font(.system(.subheadline) .weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Image(systemName: SensorIconConstants.sensorAcoustics[0].icon)
                                        .frame(width: 30, height: 20)
                                    
                                    RRRangeSliderSwiftUI(
                                        minValue: self.$minValueNoise, // mimimum value
                                        maxValue: self.$maxValueNoise, // maximum value
    //                                    minLabel: "0", // mimimum Label text
    //                                    maxLabel: "100", // maximum Label text
                                        minLabelBound: Float(SensorIconConstants.sensorAcoustics[0].minValue),
                                        maxLabelBound: Float(SensorIconConstants.sensorAcoustics[0].maxValue),
                                        sliderWidth: sliderWidth, // set slider width
                                        sliderHeight: CGFloat(30.0),
                                        //                            backgroundTrackColor: Color.pink.opacity(0.5), // track color
                                        leftTrackColor:SensorIconConstants.sensorAcoustics[0].color1,
                                        rightTrackColor:SensorIconConstants.sensorAcoustics[0].color3,
                                        selectedTrackColor: SensorIconConstants.sensorAcoustics[0].color2, // track color
                                        globeColor: SensorIconConstants.sensorAcoustics[0].color2, // globe background color
                                        globeBackgroundColor: Color.white, // globe rounded border color
                                        sliderMinMaxValuesColor: Color.black // all text label color
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    Text(SensorIconConstants.sensorAcoustics[0].unit)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(Color.black)
                                        .font(.system(.subheadline))
                                    
                                }

                            }
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
    //                    .padding(.all, 10)
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(15)
                        
                        HStack{
                            Image(systemName: "exclamationmark.triangle")
                                .frame(width: 30, height: 20)
                            Text("These values are very personal as the sensors read from your body and the environment. The absolute value may not be the same on other sensing devices.")
                                .font(.system(.caption2))
                        }
                    }
                    .padding()


                
                
            }.navigationTitle("Settings")
        }
        
        .onAppear{
//            let value1: Float? = UserDefaults.standard.float(forKey: "minValueTemp")
//            if value1 != nil {
//                print(UserDefaults.standard.float(forKey: "minValueTemp"))
//                self.minValueTemp = UserDefaults.standard.float(forKey: "minValueTemp") * sliderWidth
//            }
//
//            let value2: Float? = UserDefaults.standard.float(forKey: "maxValueTemp")
//            if value2 != nil{
//                print(UserDefaults.standard.float(forKey: "minValueTemp"))
//                self.maxValueTemp = UserDefaults.standard.float(forKey: "maxValueTemp") * sliderWidth
//            }
            
            
            
            
            if UserDefaults.standard.float(forKey: "minValueTemp") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorThermal[0].color1Position, forKey: "minValueTemp")
                self.minValueTemp = UserDefaults.standard.float(forKey: "minValueTemp") * sliderWidth
            }else{
                self.minValueTemp = UserDefaults.standard.float(forKey: "minValueTemp") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "maxValueTemp") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorThermal[0].color3Position, forKey: "maxValueTemp")
                self.maxValueTemp = UserDefaults.standard.float(forKey: "maxValueTemp") * sliderWidth
            }else{
                self.maxValueTemp = UserDefaults.standard.float(forKey: "maxValueTemp") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "minValueHum") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorThermal[1].color1Position, forKey: "minValueHum")
                self.minValueHum = UserDefaults.standard.float(forKey: "minValueHum") * sliderWidth
            }else{
                self.minValueHum = UserDefaults.standard.float(forKey: "minValueHum") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "maxValueHum") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorThermal[1].color3Position, forKey: "maxValueHum")
                self.maxValueHum = UserDefaults.standard.float(forKey: "maxValueHum") * sliderWidth
            }else{
                self.maxValueHum = UserDefaults.standard.float(forKey: "maxValueHum") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "minValueLightIntensity") == 0 {
                self.minValueLightIntensity = Float(SensorIconConstants.sensorVisual[0].color1Position) * sliderWidth
            }else{
                self.minValueLightIntensity = UserDefaults.standard.float(forKey: "minValueLightIntensity") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "maxValueLightIntensity") == 0 {
                self.maxValueLightIntensity = Float(SensorIconConstants.sensorVisual[0].color3Position) * sliderWidth
            }else{
                self.maxValueLightIntensity = UserDefaults.standard.float(forKey: "maxValueLightIntensity") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "minValueNoise") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorAcoustics[0].color1Position, forKey: "minValueNoise")
                minValueNoise = UserDefaults.standard.float(forKey: "minValueNoise") * sliderWidth
            }else{
                minValueNoise = UserDefaults.standard.float(forKey: "minValueNoise") * sliderWidth
            }

            if UserDefaults.standard.float(forKey: "maxValueNoise") == 0 {
                UserDefaults.standard.set(SensorIconConstants.sensorAcoustics[0].color3Position, forKey: "maxValueNoise")
                maxValueNoise = UserDefaults.standard.float(forKey: "maxValueNoise") * sliderWidth
            }else{
                maxValueNoise = UserDefaults.standard.float(forKey: "maxValueNoise") * sliderWidth
            }
        }
    }
    

    
    func connectToAirSpec(){
        if !Array(receiver.discoveredPeripherals).isEmpty{
            for peripheral in Array(receiver.discoveredPeripherals){
                if(peripheral.name!.contains("STM32WB") || peripheral.name!.contains("$user_id") || peripheral.name!.contains(receiver.GLASSNAME)){
                    receiver.connect(to: peripheral)
                }
            }
        }
        
    }
//
//    /// A view to display the Bluetooth peripheral that this device is currently connected to.
//    @ViewBuilder
//    var connectedPeripheral: some View {
//        if let peripheral = receiver.connectedPeripheral {
//            Text(peripheral.name ?? "unnamed peripheral")
//                .onTapGesture { receiver.disconnect(from: peripheral, mustDisconnect: true) }
//        }
//    }
//
//    var showData: some View {
//        Text(receiver.glassesData.sensorData)
//    }
//
    private func toggleScanning() {
        guard receiver.centralManager.state == .poweredOn else {
            return
        }

        if receiver.isScanning {
            receiver.stopScanning()
        } else {
            receiver.startScanning()
        }
    }
    

}






///// This view displays an interface for discovering and connecting to Bluetooth peripherals.
//struct SettingView: View {
//
//    @EnvironmentObject private var receiver: BluetoothReceiver
////    var receiver: BluetoothReceiver
////    private var notificationHandler = ExtensionDelegate.instance.notificationHandler
//
//
//    var body: some View {
//
//        NavigationView{
//            ZStack{
//                List {
//                    Button(action: receiver.testLight) {
//                            Label("Test LED", systemImage: "lightbulb.led.wide.fill")
//                    }
//
//                    scanButton.foregroundColor(Color.blue)
//                    Section(header: Text("Connected")) {
//                        connectedPeripheral
//                    }
//                    Section(header: Text("Discovered")) {
//                        discoveredPeripherals
//                    }
//                    Section(header: Text("Datastream")){
//                        showData
//                    }
//
//
//                }
//
//            }
//            .navigationTitle("Settings")
//        }
//    }
//
//
//
//    /// A button to start and stop the scanning process.
//    var scanButton: some View {
//        Button("\(receiver.isScanning ? "Scanning..." : "Scan")") {
//            toggleScanning()
//        }
//    }
//
//    /// A switch to enable the scan to alert functionality.
////    private var alertScanSwitch: some View {
////        Toggle("Scan to alert", isOn: $receiver.scanToAlert)
////    }
//
//    /// A view to list the peripherals that the system discovers during the scan.
//    var discoveredPeripherals: some View {
//        ForEach(Array(receiver.discoveredPeripherals), id: \.identifier) { peripheral in
//            Text(peripheral.name ?? "unnamed peripheral")
//                .onTapGesture { receiver.connect(to: peripheral) }
//        }
//    }
//
//    /// A view to display the Bluetooth peripheral that this device is currently connected to.
//    @ViewBuilder
//    var connectedPeripheral: some View {
//        if let peripheral = receiver.connectedPeripheral {
//            Text(peripheral.name ?? "unnamed peripheral")
//                .onTapGesture { receiver.disconnect(from: peripheral, mustDisconnect: true) }
//        }
//    }
//
//    var showData: some View {
//        Text(receiver.glassesData.sensorData)
//    }
//
//    private func toggleScanning() {
//        guard receiver.centralManager.state == .poweredOn else {
//            return
//        }
//
//        if receiver.isScanning {
//            receiver.stopScanning()
//        } else {
//            receiver.startScanning()
//        }
//    }
//}

struct SettingView_Previews: PreviewProvider {
    static let receiver = BluetoothReceiver(service: BluetoothConstants.airspecServiceUUID, characteristic: BluetoothConstants.airspecTXCharacteristicUUID)
    static var previews: some View {
        SettingView()
            .environmentObject(receiver)
    }
}

