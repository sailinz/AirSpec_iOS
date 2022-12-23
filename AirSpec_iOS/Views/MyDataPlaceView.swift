//
//  MyDataPlaceView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 23.12.22.
//

import SwiftUI

struct MyDataPlaceView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    let pieRadius:CGFloat = 100
    let comfyColor:Color = .mint
    let uncomfyColor:Color = .pink
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            VStack{
                Text("Office")
                    .font(.system(.subheadline) .weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                PieChartView(
                    slices: [
                        (Double(Int.random(in: 1...10)), comfyColor),
                        (Double(Int.random(in: 1...10)), uncomfyColor)
                    ])
                    .frame(width: pieRadius,height: pieRadius)
                
                VStack(alignment: .leading){
                    HStack(){
                        Image("not_comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(uncomfyColor)
                            .frame(width: 6, height:6)
                        Text("Want warmer " + "@" + " 16 °C")
                            .font(.system(.caption2))
                    }
                    HStack(){
                        Image("comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(comfyColor)
                            .frame(width: 6, height:6)
                        Text("collaborative")
                            .font(.system(.caption2))
                    }
                }
                
                
            }
//                    .padding()
            
            VStack{
                Text("Home")
                    .font(.system(.subheadline) .weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                PieChartView(
                    slices: [
                        (Double(Int.random(in: 1...10)), comfyColor),
                        (Double(Int.random(in: 1...10)), uncomfyColor)
                    ])
                    .frame(width: pieRadius,height: pieRadius)
                VStack(alignment: .leading){
                    HStack(){
                        Image("not_comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(uncomfyColor)
                            .frame(width: 6, height:6)
                        Text("Want warmer " + "@" + " 16 °C")
                            .font(.system(.caption2))
                    }
                    HStack(){
                        Image("comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(comfyColor)
                            .frame(width: 6, height:6)
                        Text("collaborative")
                            .font(.system(.caption2))
                    }
                }
            }
//                    .padding()
            
            VStack{
                Text("Other indoor")
                    .font(.system(.subheadline) .weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                PieChartView(
                    slices: [
                        (Double(Int.random(in: 1...10)), comfyColor),
                        (Double(Int.random(in: 1...10)), uncomfyColor)
                    ])
                    .frame(width: pieRadius,height: pieRadius)
                VStack(alignment: .leading){
                    HStack(){
                        Image("not_comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(uncomfyColor)
                            .frame(width: 6, height:6)
                        Text("Want warmer " + "@" + " 16 °C")
                            .font(.system(.caption2))
                    }
                    HStack(){
                        Image("comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(comfyColor)
                            .frame(width: 6, height:6)
                        Text("collaborative")
                            .font(.system(.caption2))
                    }
                }
            }
//                    .padding()
            
            VStack{
                Text("Outdoor")
                    .font(.system(.subheadline) .weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                PieChartView(
                    slices: [
                        (Double(Int.random(in: 1...10)), comfyColor),
                        (Double(Int.random(in: 1...10)), uncomfyColor)
                    ])
                    .frame(width: pieRadius,height: pieRadius)
                VStack(alignment: .leading){
                    HStack(){
                        Image("not_comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(uncomfyColor)
                            .frame(width: 6, height:6)
                        Text("Want warmer " + "@" + " 16 °C")
                            .font(.system(.caption2))
                    }
                    HStack(){
                        Image("comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(comfyColor)
                            .frame(width: 6, height:6)
                        Text("collaborative")
                            .font(.system(.caption2))
                    }
                }
            }
//                    .padding()
            
            VStack{
                Text("Transportation")
                    .font(.system(.subheadline) .weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                PieChartView(
                    slices: [
                        (Double(Int.random(in: 1...10)), comfyColor),
                        (Double(Int.random(in: 1...10)), uncomfyColor)
                    ])
                    .frame(width: pieRadius,height: pieRadius)
                VStack(alignment: .leading){
                    HStack(){
                        Image("not_comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(uncomfyColor)
                            .frame(width: 6, height:6)
                        Text("Want warmer " + "@" + " 16 °C")
                            .font(.system(.caption2))
                    }
                    HStack(){
                        Image("comfy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(comfyColor)
                            .frame(width: 6, height:6)
                        Text("collaborative")
                            .font(.system(.caption2))
                    }
                }
            }
//                    .padding()


            

            
            
            
        }
    }
}

struct MyDataPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        MyDataPlaceView()
    }
}
