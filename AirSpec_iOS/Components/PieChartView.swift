//
//  PieChart.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 22.12.22.
//  Modified from jrturton's answer https://stackoverflow.com/questions/73742810/swift-charts-ios-16-pie-donut-chart

import SwiftUI

struct PieChartView: View {

    @State var slices: [(Double, Color)]

    var body: some View {
        ZStack{
            Canvas { context, size in
                let total = slices.reduce(0) { $0 + $1.0 }
                context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
                var pieContext = context
                pieContext.rotate(by: .degrees(-90))
                let radius = min(size.width, size.height) * 0.48
                var startAngle = Angle.zero
                for (value, color) in slices {
                    
                    let angle = Angle(degrees: 360 * (value / total))
                    let endAngle = startAngle + angle
                    let path = Path { p in
                        p.move(to: .zero)
                        p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        p.closeSubpath()
                    }
                    pieContext.fill(path, with: .color(color))
                    if color == .pink{
                        pieContext.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    }else{
                        pieContext.stroke(path, with: .color(.mint), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    }
                    
                    startAngle = endAngle
                }
            }
//            .aspectRatio(0.15, contentMode: .fit)
            
            let total = slices.reduce(0) { $0 + $1.0 }
            Image("comfy")
                .resizable()
                .frame(width: 15, height:  15)
                .foregroundColor(Color.white)
                .offset(x: CGFloat(sin(Double.pi * (slices[0].0 / total)) * 30.0), y: -CGFloat(cos(Double.pi * (slices[0].0 / total)) * 30.0))
            
            Image("not_comfy")
                .resizable()
                .frame(width: 15, height:  15)
                .foregroundColor(Color.white)
                .offset(x: -CGFloat(sin(Double.pi * (slices[1].0 / total)) * 30), y: -CGFloat(cos(Double.pi * (slices[1].0 / total)) * 30))
            
            
        }
        
    }
}

struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        PieChartView(slices: [
            (6, .mint),
            (3, .pink)
        ])
    }
}
