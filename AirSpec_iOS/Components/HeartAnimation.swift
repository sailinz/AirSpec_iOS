//
//  HeartAnimation.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 19.12.22.
//

import SwiftUI
import HealthKit

struct HeartAnimation: View {

    @State var animate: Bool = false
    @State var heartRate: Double? = nil
    @State var opacityT = SensorIconConstants.goodStateOpacity
    @State var opacityAQ = SensorIconConstants.goodStateOpacity
    @State var opacityN = SensorIconConstants.goodStateOpacity
    @State var opacityL = SensorIconConstants.goodStateOpacity
    
    #if os(watchOS)
    @ObservedObject var dataReceivedWatch: SensorData
    #endif
    
    var healthStore = HKHealthStore()
    
    
    let timer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
        
    
    var body: some View {
        #if os(iOS)
            ZStack{
                ZStack{
                    CrookedText(text: "Lighting", radius:90)
                        .rotationEffect(.radians(.pi*5/4))
                        .offset(x:-30,y:30)
                    
                    CrookedText(text: "Noise", radius:90)
                        .rotationEffect(.radians(.pi*3/4))
                        .offset(x:20,y: 35)
                    
                    CrookedText(text: "Air quality", radius:90)
                        .rotationEffect(.radians(.pi/4))
                        .offset(x:40,y: 10)
                    
                    CrookedText(text: "Thermal", radius:90)
                        .rotationEffect(.radians(.pi*7/4))
                        .offset(x:-30,y: 5)
                }
                .scaleEffect(animate ? 1.1:1.0)
                .offset(y: animate ? -5 : 0)
                
                
                ZStack{
                    
                    Image("heart_visual")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .offset(x:-30,y:55)
                        .opacity(opacityL)
                    
                    
                    
                    Image("heart_noise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                        .offset(x:40,y:60)
                        .opacity(opacityN)

                    
                    Image("heart_aq")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                        .offset(x:50,y: -15)
                        .opacity(opacityAQ)
                    
                    
                    Image("heart_thermal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                        .offset(x:-40,y: 0)
                        .opacity(opacityT)
                    
                    
                    Text(heartRate.map {String(format: "%.0f", $0)+" BPM" } ?? "-- BPM")
                        .font(.system(.largeTitle, design: .rounded) .weight(.heavy))
                        .foregroundColor(.white)
                        .offset(x:0, y:30)
                        .onReceive(timer) { _ in
                            fetchLatestHeartRate()
                        }
                }
                .scaleEffect(animate ? 1.1:1.0)
                .shadow(
                    color:animate ? Color.red.opacity(0.7) : Color.pink.opacity(0.7),
                    radius:animate ? 30 : 10,
                    x: 0,
                    y: animate ? 50:40)
                .offset(y: animate ? -5 : 0)

            }
                    
            .onAppear{
                autorizeHealthKit()
                addAnimation()
            }
        #endif

            
        #if os(watchOS)
            NavigationView {
                ZStack{
                    NavigationLink(destination: VisualView(dataReceivedWatch: dataReceivedWatch)) {
                        Image("heart_visual")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .offset(x:50,y:55)
                            .opacity(opacityL)
                        CrookedText(text: "Lighting", radius:90)
                            .rotationEffect(.radians(.pi*5/4))
                            .offset(x:-90,y:30)
                            .shadow(
                                color:Color.white.opacity(0.8),
                                radius:2)
                    }.buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AcousticsView()) {
                        Image("heart_noise")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120)
                            .offset(x:120,y:60)
                            .opacity(opacityN)
                        CrookedText(text: "Noise", radius:90)
                            .rotationEffect(.radians(.pi*3/4))
                            .offset(x:-60,y: 35)
                            .shadow(
                                color:Color.white.opacity(0.8),
                                radius:2)
                    }.buttonStyle(PlainButtonStyle())
                    
                    
                    NavigationLink(destination: AirQualityView(dataReceivedWatch: dataReceivedWatch)) {
                        Image("heart_aq")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120)
                            .offset(x:130,y: -15)
                            .opacity(opacityAQ)
                        CrookedText(text: "Air quality", radius:90)
                            .rotationEffect(.radians(.pi/4))
                            .offset(x:-40,y: 10)
                            .shadow(
                                color:Color.white.opacity(0.8),
                                radius:2)
                    }.buttonStyle(PlainButtonStyle())
                    
                    
                    NavigationLink(destination: ThermalView(dataReceivedWatch: dataReceivedWatch)) {
                        Image("heart_thermal")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120)
                            .offset(x:40,y: 0)
                            .opacity(opacityT)
                        CrookedText(text: "Thermal", radius:90)
                            .rotationEffect(.radians(.pi*7/4))
                            .offset(x:-90,y: 5)
                            .shadow(
                                color:Color.white.opacity(0.8),
                                radius:2)
                    }.buttonStyle(PlainButtonStyle())
                    
                    
                    Text(heartRate.map {String(format: "%.0f", $0)+" BPM" } ?? "-- BPM")
                        .font(.system(.largeTitle, design: .rounded) .weight(.heavy))
                        .foregroundColor(.white)
                        .offset(x:0, y:30)
                        .onReceive(timer) { _ in
                            fetchLatestHeartRate()
                        }
                }
                .scaleEffect(animate ? 0.6:0.5)
                .offset(y:-15)
                .shadow(
                    color:animate ? Color.red.opacity(0.7) : Color.pink.opacity(0.7),
                    radius:animate ? 30 : 10,
                    x: 0,
                    y: animate ? 30:20)
                .offset(y: animate ? -5 : 0)
                
                .onAppear{
                    autorizeHealthKit()
                    addAnimation()
                }
            
            }
        #endif
        
    }
    
    /// heart animation: https://www.youtube.com/watch?v=KamCx-Hfdxk&list=PL203Utzojrl7KLE6Foas7dXLOkcffDWMo&index=6
    func addAnimation(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
            withAnimation(
                Animation
                    .easeInOut(duration:1.2)
                    .repeatForever()
            ){
                animate.toggle()
            }
        }
    }
    
    func autorizeHealthKit() {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    func fetchLatestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
          guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
            // handle the error or return if no heart rate samples are available
            return
          }

          let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
          self.heartRate = heartRate
//            print(heartRate)
        }
        healthStore.execute(query)
    }
    

    
}

//struct HeartAnimation_Previews: PreviewProvider {
//    static var previews: some View {
//        HeartAnimation()
//    }
//}
