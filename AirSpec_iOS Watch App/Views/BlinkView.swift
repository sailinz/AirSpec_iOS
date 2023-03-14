//
//  BlinkView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZhongS on 3/13/23.
//

import SwiftUI
//import WatchKit÷
import Foundation

struct BlinkView: View {
    @State var whereToLook:String = "left"
    @Binding var eyeCalibration:Bool

    
    var body: some View {
        VStack{
            LookWhereView(whereToLook: $whereToLook)
            Button(action:{
                switch whereToLook {
                case "left":
                    whereToLook = "right"
                case "right":
                    whereToLook = "up"
                case "up":
                    whereToLook = "down"
                case "down":
                    whereToLook = "blink"
                case "blink":
                    eyeCalibration = false
                    break
                default:
                    break
                }
            }){
                Image(systemName: "chevron.right.circle")
                    .font(.system(size:20, weight:.bold))
                    .foregroundColor(.mint)
            }
            .clipShape(Circle())
        }
    }
   
}

struct LookWhereView: View{
    let width: CGFloat = 5 // width of the ring
    let radius: CGFloat = 70 // radius of the ring
    let circleDiameter: CGFloat = 30 // diameter of the circle
    var circleOffset: CGFloat = -20// offset of the circle from the left edge
    @State private var isCircleOffset = false
    @Binding var whereToLook: String
    var lookTimer: DispatchSourceTimer? = DispatchSource.makeTimerSource()
    
    var body: some View {
        VStack {
            // Outer ring
            ZStack{
                Circle()
                    .strokeBorder(Color.mint, lineWidth: width)
                    .frame(width: radius, height: radius)
                    .opacity(!isCircleOffset ? {
                        switch whereToLook {
                        case "blink":
                            return 0.2
                        default:
                            return 0.8
                        }
                    }() : 0.8)
                
                
                // Inner circle
                Circle()
                    .foregroundColor(.mint)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .opacity(!isCircleOffset ? {
                        switch whereToLook {
                        case "blink":
                            return 0.2
                        default:
                            return 0.1
                        }
                    }() : 1)
                    .offset(x: isCircleOffset ? {
                           switch whereToLook {
                           case "left":
                               return circleOffset
                           case "right":
                               return -circleOffset
                           case "up":
                               return 0
                           case "down":
                               return 0
                           default:
                               return 0
                           }
                    }() : 0, y: isCircleOffset ? {
                        switch whereToLook {
                        case "left":
                            return 0
                        case "right":
                            return 0
                        case "up":
                            return circleOffset
                        case "down":
                            return -circleOffset
                        default:
                            return 0
                        }
                 }() : 0)
                    
                
                Circle()
                    .foregroundColor(.white)
                    .frame(width: circleDiameter/2, height: circleDiameter)
                    .opacity(!isCircleOffset ? {
                        switch whereToLook {
                        case "blink":
                            return 0.2
                        default:
                            return 0.1
                        }
                    }() : 1)
                    .offset(x: isCircleOffset ? {
                           switch whereToLook {
                           case "left":
                               return (circleOffset-circleDiameter/2+circleDiameter/3)
                           case "right":
                               return -(circleOffset-circleDiameter/2+circleDiameter/3)
                           case "up":
                               return 0
                           case "down":
                               return 0
                           default:
                               return 0
                           }
                    }() : 0, y: isCircleOffset ? {
                        switch whereToLook {
                        case "left":
                            return 0
                        case "right":
                            return 0
                        case "up":
                            return (circleOffset-circleDiameter/2+circleDiameter/3)
                        case "down":
                            return -(circleOffset-circleDiameter/2+circleDiameter/3)
                        default:
                            return 0
                        }
                 }() : 0)
            }
            if isCircleOffset{
                if(whereToLook != "blink"){
                    Text("Look **\(whereToLook)**")
                        .fixedSize(horizontal: false, vertical: false)
                }else{
                    Text("**Open** eyes")
                        .fixedSize(horizontal: false, vertical: false)
                }
            }else{
                if(whereToLook != "blink"){
                    Text("Back to **center**")
                        .fixedSize(horizontal: false, vertical: false)
                }else{
                    Text("**Close** eyes")
                        .fixedSize(horizontal: false, vertical: false)
                }
            }
           
                
        }
        .onAppear {
            // Start the animation look
            lookTimer?.schedule(deadline: .now(), repeating: 1.8)
            lookTimer?.setEventHandler {
                withAnimation(.easeInOut(duration: 1.0)) {
                    self.isCircleOffset.toggle()
                }
                WKInterfaceDevice.current().play(.notification)
                
                if isCircleOffset{
                    if(whereToLook == "left"){
                        RawDataViewModel.addMetaDataToRawData(payload: "left", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "right"){
                        RawDataViewModel.addMetaDataToRawData(payload: "right", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "up"){
                        RawDataViewModel.addMetaDataToRawData(payload: "up", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "down"){
                        RawDataViewModel.addMetaDataToRawData(payload: "down", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "blink"){
                        RawDataViewModel.addMetaDataToRawData(payload: "blink eye open", timestampUnix: Date(), type: 5)
                    }
                }else{
                    if(whereToLook == "left"){
                        RawDataViewModel.addMetaDataToRawData(payload: "left to center", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "right"){
                        RawDataViewModel.addMetaDataToRawData(payload: "right to center", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "up"){
                        RawDataViewModel.addMetaDataToRawData(payload: "up to center", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "down"){
                        RawDataViewModel.addMetaDataToRawData(payload: "down to center", timestampUnix: Date(), type: 5)
                    }else if(whereToLook == "blink"){
                        RawDataViewModel.addMetaDataToRawData(payload: "blink eye close", timestampUnix: Date(), type: 5)
                    }
                }
            }
            lookTimer?.resume()
            
        }
    }
    
    
}

struct LookWhereView_Previews: PreviewProvider {
    static var previews: some View {
        let whereToLook = Binding.constant("right") // Create a binding variable with an initial value of "left"
        return LookWhereView(whereToLook: whereToLook)
    }
}



struct BlinkView_Previews: PreviewProvider {
    static var previews: some View {
        let eyeCalibrationDone = Binding.constant(false) // Create a binding variable with an initial value of "left"
        return BlinkView(eyeCalibration:eyeCalibrationDone)
    }
}
