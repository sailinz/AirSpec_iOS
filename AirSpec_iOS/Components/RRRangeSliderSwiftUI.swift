//
//  RRRangeSliderSwiftUI.swift
//  AirSpec_iOS
//
//  Created by Rahul-Mayani and modified by ZHONG Sailin on 22.12.22.
//  https://github.com/Rahul-Mayani/RRRangeSliderSwiftUI.git

import SwiftUI

public struct RRRangeSliderSwiftUI: View {
    /// ` Slider` Binding min & max values
    @Binding var minValue: Float
    @Binding var maxValue: Float
            
    /// Set slider min & max Label values
//    let minLabel: String
//    let maxLabel: String
    let minLabelBound:Float
    let maxLabelBound:Float
    
    /// Set slider width
    let sliderWidth: Float
    
    /// `Slider` background track color
//    let backgroundTrackColor: Color
    let leftTrackColor: Color
    let rightTrackColor: Color
    /// `Slider` selected track color
    let selectedTrackColor: Color
    
    /// Globe background color
    let globeColor: Color
    /// Globe rounded boarder color
    let globeBackgroundColor: Color
    
    /// Slider min & max static and dynamic labels value color
    let sliderMinMaxValuesColor: Color
    
    let sliderHeight:CGFloat
    
    /// `Slider` init
    public init(minValue: Binding<Float>,
                maxValue: Binding<Float>,
//                minLabel: String = "0",
//                maxLabel: String = "100",
                minLabelBound: Float = 0.0,
                maxLabelBound: Float = 100.0,
                sliderWidth: Float = 0,
                sliderHeight: CGFloat = 30,
//                backgroundTrackColor: Color = Color(UIColor.systemTeal).opacity(0.3),
                leftTrackColor:Color = Color.pink.opacity(0.3),
                rightTrackColor:Color = Color.pink.opacity(0.3),
                selectedTrackColor: Color = Color.pink.opacity(25),
                globeColor: Color = Color.black,
                globeBackgroundColor: Color = Color.white,
                sliderMinMaxValuesColor: Color = Color.white) {
        self._minValue = minValue
        self._maxValue = maxValue
//        self.minLabel = minLabel
//        self.maxLabel = maxLabel
        self.minLabelBound = minLabelBound
        self.maxLabelBound = maxLabelBound
        self.sliderWidth = sliderWidth
        self.sliderHeight = sliderHeight
//        self.backgroundTrackColor = backgroundTrackColor
        self.leftTrackColor = leftTrackColor
        self.rightTrackColor = rightTrackColor
        self.selectedTrackColor = selectedTrackColor
        self.globeColor = globeColor
        self.globeBackgroundColor = globeBackgroundColor
        self.sliderMinMaxValuesColor = sliderMinMaxValuesColor
       
    }
    
    /// `Slider` view setup
    public var body: some View {
        
        VStack {
                
//            /// `Slider` start & end static values show in view
//            HStack {
//                // start value
//                Text(minLabel)
////                    .offset(x: 28, y: 20)
//                    .frame(width: 30, height: 30, alignment: .leading)
//                    .foregroundColor(sliderMinMaxValuesColor)
//
//                Spacer()
//                // end value
//                Text(maxLabel)
////                    .offset(x: -18, y: 20)
//                    .frame(width: 30, height: 30, alignment: .trailing)
//                    .foregroundColor(sliderMinMaxValuesColor)
//            }.padding()
            
            /// `Slider` track view with glob view
//            ZStack (alignment: Alignment(horizontal: .leading, vertical: .center), content: {
            ZStack (alignment: Alignment(horizontal: .leading, vertical: .top), content: {
                // background track view

                Capsule()
                    .fill(rightTrackColor)
//                    .offset(x: CGFloat(self.maxValue) - sliderHeight)
                    .frame(width: CGFloat(self.sliderWidth), height: sliderHeight)
                
                Capsule()
                    .fill(leftTrackColor)
                    .frame(width: CGFloat(self.minValue) + sliderHeight, height: sliderHeight)
                
                // selected track view
                Capsule()
                    .fill(selectedTrackColor)
                    .offset(x: CGFloat(self.minValue))
                    .frame(width: CGFloat((self.maxValue) - self.minValue), height: 30)
                
                // minimum value glob view
                Circle()
                    .fill(globeColor)
                    .frame(width: sliderHeight, height: sliderHeight)
                    .background(Circle().stroke(globeBackgroundColor, lineWidth: 3))
                    .shadow(
                        color:Color.white.opacity(0.5),
                        radius:2)
                    .offset(x: CGFloat(self.minValue))
                    .gesture(DragGesture().onChanged({ (value) in
                        /// drag validation
                        if CGFloat(value.location.x) > 0 &&
                           CGFloat(value.location.x) <= (CGFloat(self.sliderWidth) - sliderHeight) &&
                           CGFloat(value.location.x) <  (CGFloat(self.maxValue) - sliderHeight)  {
                            // set min value of slider
                            self.minValue = Float(value.location.x)
                        }
                    }))
                
                // minimum value text draw inside minimum glob view
                Text(String(format: "%.0f", (CGFloat(self.minValue) / (CGFloat(self.sliderWidth) - sliderHeight)) * CGFloat(self.maxLabelBound - self.minLabelBound) + CGFloat(self.minLabelBound)   ))
                    .offset(x: CGFloat(self.minValue))
                    .frame(width: sliderHeight, height: sliderHeight, alignment: .center)
                    .foregroundColor(sliderMinMaxValuesColor)
                    .font(.system(.subheadline, design: .rounded) .weight(.semibold))
                      
                // maximum value glob view
                Circle()
                    .fill(globeColor)
                    .frame(width: sliderHeight, height: sliderHeight)
                    .background(Circle().stroke(globeBackgroundColor, lineWidth: 3))
                    .offset(x: CGFloat(self.maxValue) - sliderHeight)
                    .gesture(DragGesture().onChanged({ (value) in
                        /// drag validation
                        if CGFloat(value.location.x) <= CGFloat(self.sliderWidth) &&
                           CGFloat(value.location.x) >  (CGFloat(self.minValue) + sliderHeight){
                            // set max value of slider
                            self.maxValue = Float(value.location.x )
                        }
                    }))
                
                // maximum value text draw inside maximum glob view
                Text(String(format: "%.0f", (  (CGFloat(self.maxValue) - sliderHeight) / (CGFloat(self.sliderWidth) - sliderHeight) ) * CGFloat(self.maxLabelBound - self.minLabelBound) + CGFloat(self.minLabelBound)    ))
                    .offset(x: CGFloat(self.maxValue) - sliderHeight)
                    .frame(width: sliderHeight, height: sliderHeight, alignment: .center)
                    .foregroundColor(sliderMinMaxValuesColor)
                    .font(.system(.subheadline, design: .rounded) .weight(.semibold))
//                    .padding(.trailing)
            })
//            .padding()
            
            
            
        }
    }
}

struct RRRangeSliderSwiftUI_Previews: PreviewProvider {

    @State static var minValue: Float = 0.0
    @State static var maxValue: Float = Float(UIScreen.main.bounds.width)
    
    static var previews: some View {
        RRRangeSliderSwiftUI(minValue: $minValue, maxValue: $maxValue)
    }
}
