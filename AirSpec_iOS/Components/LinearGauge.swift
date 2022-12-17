//
//  Gauge.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.12.22.
//

import SwiftUI

struct LinearGauge<Content: View>: View {
    let content:Content
    @State private var current = 60.0
    @State private var minValue = 50.0
    @State private var maxValue = 100.0
    private var color1 = Color.blue
    private var color2 = Color.white
    private var color3 = Color.red
    @State private var color1Position = 0.3
    @State private var color2Position = 0.6
    @State private var color3Position = 0.9
//    let gradientColors = Gradient(stops: [
//        .init(color: Color.blue, location: 0.2),
//        .init(color: Color.pink, location: 0.4),
//        .init(color: Color.yellow, location: 0.8)
//    ]
//    )
    
    init(current: Double, minValue: Double, maxValue: Double, color1: Color, color2: Color, color3: Color, color1Position: Double, color2Position: Double, color3Position: Double, @ViewBuilder content:() -> Content){
        self.content = content()
        self.current = current
        self.minValue = minValue
        self.maxValue = maxValue
        self.color1 = color1
        self.color2 = color2
        self.color3 = color3
        self.color1Position = color1Position
        self.color2Position = color2Position
        self.color3Position = color3Position
    }

    var body: some View {
        let gradientColors = Gradient(stops: [
            .init(color: color1, location: color1Position),
            .init(color: color2, location: color2Position),
            .init(color: color3, location: color3Position)
        ]
        )
        HStack{
            Image(systemName: "thermometer.low")
//                .foregroundColor(color1)
            Gauge(value: current, in: minValue...maxValue) {
                    } currentValueLabel: {
                        Text("\(Int(current))")
                    } minimumValueLabel: {
                        Text("\(Int(minValue))")
                    } maximumValueLabel: {
                        Text("\(Int(maxValue))")
                    }
                    .tint(LinearGradient(gradient: Gradient(stops: [
                        .init(color: color1, location: 0.45),
                        .init(color: color3, location: 0.55),
                    ]), startPoint: .leading, endPoint: .trailing))
        }
        

    }
}

struct LinearGauge_Previews: PreviewProvider {
    static var previews: some View {
        LinearGauge(current: 60.0, minValue: 50.0, maxValue: 100.0, color1: Color.blue, color2: Color.white, color3: Color.red, color1Position: 0.3, color2Position: 0.6, color3Position: 0.5){
            
        }
    }
}



