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
    @State private var heartRate: Double? = nil
    @State private var opacityT = SensorIconConstants.goodStateOpacity
    @State private var opacityAQ = SensorIconConstants.goodStateOpacity
    @State private var opacityN = SensorIconConstants.goodStateOpacity
    @State private var opacityL = SensorIconConstants.goodStateOpacity
   
    private var healthStore = HKHealthStore()
    
    
    let timer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
        
    
    var body: some View {
        ZStack {
            
//            Image(systemName: "heart.fill")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 200, height: 200)
//                .foregroundColor(.pink)
        
            
            Image("heart_visual")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
                .offset(x:-30,y:55)
                .opacity(opacityL)
            CrookedText(text: "Lighting", radius:90)
//                .bold()
                .rotationEffect(.radians(.pi*5/4))
                .offset(x:-30,y:30)
            
            Image("heart_noise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120)
                .offset(x:40,y:60)
                .opacity(opacityN)
            CrookedText(text: "Noise", radius:90)
//                .bold()
                .rotationEffect(.radians(.pi*3/4))
                .offset(x:20,y: 35)
            

            
            Image("heart_aq")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120)
                .offset(x:50,y: -15)
                .opacity(opacityAQ)
            CrookedText(text: "Air quality", radius:90)
//                .bold()
                .rotationEffect(.radians(.pi/4))
                .offset(x:40,y: 10)

            
            Image("heart_thermal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120)
                .offset(x:-40,y: 0)
                .opacity(opacityT)
            CrookedText(text: "Thermal", radius:90)
//                .bold()
                .rotationEffect(.radians(.pi*7/4))
                .offset(x:-30,y: 5)



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
        
        .onAppear{
            autorizeHealthKit()
            addAnimation()
        }
        
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

struct HeartAnimation_Previews: PreviewProvider {
    static var previews: some View {
        HeartAnimation()
    }
}