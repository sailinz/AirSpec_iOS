//
//  Home.swift
//  AirSpec_Watch Watch App
//
//  Created by ZHONG Sailin on 03.11.22.
//  developer.apple.com/videos/play/wwdc2021/10005
import SwiftUI

struct HomeView: View {
    
    var body: some View {
//        NavigationView{
//            ZStack{
//                Text("home placeholder")
//            }
//            .navigationTitle("Home")
//        }
        
        NavigationView{
            ZStack{
                List {
                    Section(header: Text("Temperature")){
                        showDataFromInflux
                    }
                }
                
            }
            .navigationTitle("Settings")
        }
    }
    
    var showDataFromInflux: some View {
        Text("placeholder")
//        influxClient.run()
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}


