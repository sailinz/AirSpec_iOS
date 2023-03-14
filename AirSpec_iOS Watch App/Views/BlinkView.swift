//
//  BlinkView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZhongS on 3/13/23.
//

import SwiftUI
import WatchKit
import HealthKit
import Foundation

struct BlinkView: View {
    @State var whereToLook:String = "left"
    @Binding var eyeCalibration:Bool
    @State(initialValue: WorkoutDataStore())
    private var backgroundSession: WorkoutDataStore
    
    let healthStore = HKHealthStore()
    let session = HKWorkoutSession(activityType: .running, locationType: .outdoor)
    var blinkTimer: DispatchSourceTimer? = DispatchSource.makeTimerSource()
    
    var body: some View {
        ZStack{
            LookWhereView(whereToLook: $whereToLook)
//            Button(action:{
//                withAnimation{
//                    eyeCalibration = false
//                }
//            }){
//                Image(systemName: "xmark.circle")
//                    .font(.system(size:20, weight:.bold))
//                    .foregroundColor(.pink)
//            }
//            .clipShape(Circle())
        }
        .onAppear {
                self.backgroundSession.startWorkoutSession()
                // Start the animation look
                blinkTimer?.schedule(deadline: .now() + 18, repeating: 18)
                blinkTimer?.setEventHandler {
                    WKInterfaceDevice.current().play(.success)

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
                        blinkTimer?.cancel()
                        self.backgroundSession.stopWorkoutSession()
                        eyeCalibration = false
                        break
                    default:
                        break
                    }
                }
                blinkTimer?.resume()

            }
        .onDisappear{
            self.backgroundSession.stopWorkoutSession()
            blinkTimer?.cancel()

        }
        
    }
   
}

struct LookWhereView: View{
    let width: CGFloat = 5 // width of the ring
    let radius: CGFloat = 80 // radius of the ring
    let circleDiameter: CGFloat = 40 // diameter of the circle
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
                    Text("Look **\(whereToLook)** when you feel the **vibration**.")
                        .fixedSize(horizontal: false, vertical: false)
                }else{
                    Text("Then **open** your eyes when you feel the **vibration** again.")
                        .fixedSize(horizontal: false, vertical: false)
                }
                
                
            }else{
                if(whereToLook != "blink"){
                    Text("Then go back to **center** when you feel the **vibration** again.")
                        .fixedSize(horizontal: false, vertical: false)
                }else{
                    Text("**Close** your eyes when you feel the **vibration**.")
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
