//
//  Gauge.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.12.22.
//  https://www.kodeco.com/30070603-viewbuilder-tutorial-creating-reusable-swiftui-views

import SwiftUI


struct OpenCircularGauge<Content>: View where Content: View {
    let content:Content
    var current = 0.0
    var minValue = 0.0
    var maxValue = 0.0
    var color1 = Color.blue
    var color2 = Color.white
    var color3 = Color.red
    var color1Position = 0.2
    var color3Position = 0.8
    var valueTrend = 0 /// 1: increase; 0: no change; -1: decrease
    var icon = "thermometer.low"
    
    init(current: Double, minValue: Double, maxValue: Double, color1: Color, color2: Color, color3: Color, color1Position: Double, color3Position: Double, valueTrend: Int, icon: String, @ViewBuilder content:() -> Content){
        self.content = content()
        self.current = current
        self.minValue = minValue
        self.maxValue = maxValue
        self.color1 = color1
        self.color2 = color2
        self.color3 = color3
        self.color1Position = color1Position
        self.color3Position = color3Position
        self.valueTrend = valueTrend
        self.icon = icon
    }

    var body: some View {

        let gradientColors = Gradient(stops: [
            .init(color: color1, location: color1Position-0.05),
            .init(color: color2, location: color1Position+0.05),
            .init(color: color2, location: color3Position-0.05),
            .init(color: color3, location: color3Position+0.05)
        ]
        )
    
        let trendIcon = valueTrendIcon(for:valueTrend)
        
        Gauge(value: current, in: minValue...maxValue) {
        
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 18))
//                .scaleEffect(1.8)
//                .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
//                .shadow(
//                    color:.white.opacity(0.2),
//                    radius:0.2)
            
            
        } currentValueLabel: {
//                Image(systemName: trendIcon)
//                    .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
                if (!current.isInfinite && !current.isNaN){
                    if(icon.contains("thermometer")){
                        if UserDefaults.standard.bool(forKey: "isCelcius") {
                            Text(Int(current) == -1 ? "" : "\(Int(current))")
                                .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
                                .font(.system(size: 28, design: .rounded) .weight(.heavy))
                        }else{
                            Text(Int(current) == -1 ? "" : "\(Int(current * 1.8 + 34))")
                                .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
                                .font(.system(size: 28, design: .rounded) .weight(.heavy))                            
                        }
                    }else{
                        Text(Int(current) == -1 ? "" : "\(Int(current))")
                            .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
                            .font(.system(size: 28, design: .rounded) .weight(.heavy))
                    }
                    
                    
                }else{
                    Text("")
                        .foregroundColor(labelColor(for: current, minValue: minValue, maxValue: maxValue))
                        .font(.system(size: 28, design: .rounded) .weight(.heavy))
                }
            }
            .gaugeStyle(.accessoryCircular)
            .tint(gradientColors)
            .shadow(
                color:.white.opacity(0.2),
                radius:4)
        

    
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
    
    private func valueTrendIcon(for valueTrend:Int) -> String {
        if valueTrend == 1{
            return "checkmark.circle.fill"
        } else if valueTrend == 0 {
            return "minus.circle.fill"
        } else{
            return "xmark.circle.fill"
        }
    }
    
    
}

struct OpenCircularGauge_Previews: PreviewProvider {
    static var previews: some View {
        OpenCircularGauge(current: 25, minValue: 50.0, maxValue: 100.0, color1: Color.blue, color2: Color.white, color3: Color.red, color1Position: 0.3, color3Position: 0.7, valueTrend: -1, icon: "thermometer.low"){
            
        }
    }
}


