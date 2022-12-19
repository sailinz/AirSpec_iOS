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
    private var healthStore = HKHealthStore()
    
    let timer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
        
    
    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .foregroundColor(.pink)
                

            Text(heartRate.map {String(format: "%.2f", $0)+" BPM" } ?? "-- BPM")
                .font(.system(.largeTitle, design: .rounded) .weight(.heavy))
                .foregroundColor(.white)
                .offset(x:0, y:-5)
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
            print(heartRate)
        }
        healthStore.execute(query)
    }


    
}

struct HeartAnimation_Previews: PreviewProvider {
    static var previews: some View {
        HeartAnimation()
    }
}
