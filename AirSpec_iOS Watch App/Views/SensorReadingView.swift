//
//  GeometryView.swift
//  AirSpec_Watch Watch App
//
//  Created by ZHONG Sailin on 03.11.22.
//  www.youtube.com/watch?v=ma4LP8RnyI0&t=1s
//  This is just a placeholder for incomming data. It's not connected to bluetooth signal yet! 

import SwiftUI

struct SensorReadingView: View {

    private static let size: CGFloat = 40
    private static let spacingBetweenColumns:CGFloat = 4
    private static let spacingBetweenRows:CGFloat = 1
    private static let totalColumns:Int = 4
    private static let totalNum:Int = 15

    
    let gridItems = Array(
        repeating:GridItem(
            .fixed(size),
            spacing: spacingBetweenColumns,
            alignment: .center
        ),
        count: totalColumns
    )
    
    var center:CGPoint{
        CGPoint(
            x: WKInterfaceDevice.current().screenBounds.size.width*0.5, //for phone version, this should be UIScreen.main.bounds.
            y: WKInterfaceDevice.current().screenBounds.size.height*0.5)
    }
    
    var body:some View{
        ZStack{
            Color.black.edgesIgnoringSafeArea([.all])
            ScrollView([.horizontal, .vertical], showsIndicators: false){
                LazyVGrid(
                    columns: gridItems,
                    alignment:.center,
                    spacing: Self.spacingBetweenRows
                ){
                    
                    ForEach(0..<15){
                        value in
                        //                        Rectangle()
                        //                            .foregroundColor(Color.random())
                        
                        GeometryReader{proxy in
                            Image(appName(value))
                                .resizable()
                                .cornerRadius(Self.size/2)
                                .offset(
                                    x:offsetX(value),
                                    y:0
                                )
                                .opacity(0.5)
                                .overlay(
                                    Text(String(value))
                                        .offset(
                                            x:offsetX(value),
                                            y:0
                                        )
                                        .font(Font.headline.weight(.bold))
                                )
                                .scaleEffect(
                                    scale(proxy: proxy, value: value)
                                )
                            
                        }.frame(height:Self.size)
                        
                        
                    }
                    
                    
                    
                    
                }
            }
        }
    }
    
    func offsetX(_ value: Int) -> CGFloat{
        let rowNumber = value/gridItems.count
        if rowNumber % 2 == 0 {
            return Self.size/2 + Self.spacingBetweenColumns/2
        }
        return 0
    }
    
    // show icons of each sensing parameter
    func appName(_ value:Int) -> String{
        sensingItems[value%sensingItems.count]
    }
    
    // mimic the watch app screen animation
    func distanceBetweenPoints(p1: CGPoint, p2: CGPoint) -> CGFloat{
        let xDistance = abs(p2.x - p1.x)
        let yDistance = abs(p2.y - p1.y)
        return CGFloat(
            sqrt(
                pow(xDistance,2) + pow(yDistance,2)
            )
        )
    }
    
    func slope(p1: CGPoint, p2: CGPoint) -> CGFloat{
        return (p2.y - p1.y)/(p2.x - p1.x)
    }
    
    func scale(proxy: GeometryProxy, value: Int) -> CGFloat{
        let rowNumber = value / gridItems.count
        // offset for even rows
        let x = (rowNumber % 2 == 0)
        ? proxy.frame(in:.global).midX + proxy.size.width/2
        : proxy.frame(in:.global).midX
        
        let y = proxy.frame(in:.global).midY
        let maxDistanceToCenter = getDistanceFromEdgeToCenter(x: x, y: y)
        
        let currentPoint = CGPoint(x: x, y: y)
        let distanceFromCurrentPointToCenter = distanceBetweenPoints(p1: center, p2: currentPoint)
        
        let distanceDelta = min(
            abs(distanceFromCurrentPointToCenter - maxDistanceToCenter),
            maxDistanceToCenter*0.3
        )
        
        
        let scalingFactor = 3.3
        let scaleValue = distanceDelta/maxDistanceToCenter * scalingFactor
        
        return scaleValue
    }
    
    func getDistanceFromEdgeToCenter(x: CGFloat, y: CGFloat) -> CGFloat{
        let m = slope(p1: CGPoint(x:x, y:y), p2:center)
        let currentAngle = angle(slope:m)
        
        let edgeSlope = slope(p1: .zero, p2: center)
        let deviceCornerAngle = angle(slope: edgeSlope)
        
        if currentAngle > deviceCornerAngle {
            let yEdge = (y > center.y) ? center.y*2:0
            let xEdge = (yEdge - y)/m + x
            
            let edgePoints = CGPoint(x: xEdge, y: yEdge)
            return distanceBetweenPoints(p1: center, p2:edgePoints)
        }else{
            let xEdge = (x > center.x) ? center.x*2:0
            let yEdge = (xEdge - x)/m + y
            
            let edgePoints = CGPoint(x: xEdge, y: yEdge)
            return distanceBetweenPoints(p1: center, p2:edgePoints)
        }
         
        return 0.0 //dummy return value
        
    }
    
    func angle(slope:CGFloat) -> CGFloat{
        return abs(atan(slope) * 180 / .pi)
    }
    
}

struct SensorReadingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorReadingView()
    }
}


public extension Color {
    static func random(randomOpacity: Bool = false) -> Color {
            Color(
                red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                opacity: 0.7
            )
    }
}

