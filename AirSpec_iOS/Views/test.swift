//
//  test.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 06.02.23.
//

import SwiftUI

struct test: View {
    var i = 0
    var body: some View {
        ZStack{
            HStack{
                OpenCircularGauge(
                    current: -1,
                    minValue: SensorIconConstants.sensorThermal[i].minValue,
                    maxValue: SensorIconConstants.sensorThermal[i].maxValue,
                    color1: SensorIconConstants.sensorThermal[i].color1,
                    color2: SensorIconConstants.sensorThermal[i].color2,
                    color3: SensorIconConstants.sensorThermal[i].color3,
                    color1Position: 0.5,
                    color3Position: 0.5,
                    valueTrend: -1,
                    icon: SensorIconConstants.sensorThermal[i].icon){
                    }

                VStack (alignment: .leading) {
                    Text(SensorIconConstants.sensorThermal[i].name)
                        .foregroundColor(Color.white)
                        .font(.system(size: 13))
    //                                                .scaledToFit()
    //                                                .minimumScaleFactor(0.01)
    //                                                .lineLimit(1)
                    Spacer()
                    Text("90")
                        .font(.system(.title, design: .rounded) .weight(.heavy))
                        .foregroundColor(Color.white)
                }
                    
            }
            .frame(minWidth: screenWidth/2 - 50, maxHeight: 60, alignment: .leading)
            .padding(.all, 11)
            .background(Color.black.opacity(0.6))
            .cornerRadius(15)
            .shadow(
                color:Color.pink.opacity(0.4),
                radius: 4)
            
            Button(action:{
                withAnimation{
//                    feedbackButton.toggle()
                }
            }){
                ZStack{
                    Image(systemName: "info.circle")
                        .frame(width:26, height:26)
                        .foregroundColor(.white)
                }
                
            }
            .padding(.leading, 100)
            .padding(.top, 40)
        }
    }
}

struct test_Previews: PreviewProvider {
    static var previews: some View {
        test()
    }
}
