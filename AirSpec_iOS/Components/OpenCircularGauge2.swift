//
//  Gauge.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.12.22.
//

import SwiftUI


struct OpenCircularGauge2<Content: View>: View {
    @Binding var current: Double
    @Binding var minValue: Double
    @Binding var maxValue: Double
    @Binding var color1:Color
    @Binding var color2:Color
    @Binding var color3:Color
    @Binding var color1Position: Double
    @Binding var color3Position: Double

    let content: () -> Content

    var body: some View {
        content()
        let gradientColors = Gradient(stops: [
            .init(color: color1, location: color1Position),
            .init(color: color2, location: color1Position+0.1),
            .init(color: color2, location: color3Position-0.1),
            .init(color: color3, location: color3Position)
        ])
        
        Gauge(value: current, in: minValue...maxValue) {
            Image(systemName:"arrow.down.right")
                .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
            } currentValueLabel: {
                Image(systemName: "thermometer.low")
                    .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(gradientColors)
    }
    
    private func labelColor(for value: Double, minValue: Double, maxValue: Double) -> Color {
        if (current - minValue)/(maxValue - minValue) < self.color1Position {
            return color1
        } else if (current - minValue)/(maxValue - minValue) > self.color3Position {
            return color3
        } else {
            return color2
        }
    }
    
    
}

//struct OpenCircularGauge2_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenCircularGauge2(current: 55.0, minValue: 50.0, maxValue: 100.0, color1: Color.blue, color2: Color.white, color3: Color.red, color1Position: 0.3, color3Position: 0.7){
//
//        }
//    }
//}



