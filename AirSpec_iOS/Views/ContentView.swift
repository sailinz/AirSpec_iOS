//
//  ContentView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 20.11.22.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @UIApplicationDelegateAdaptor var delegate: ExtensionDelegate
    var body: some View {
        TabView{
            HomeView().environmentObject(delegate.bluetoothReceiver)
                .tabItem{
                    Label("Home", systemImage: "heart.circle.fill")
                }
            
            MyDataView()
                .tabItem{
                    Label("My data", systemImage: "person.crop.circle")
                }
            
            SettingView().environmentObject(delegate.bluetoothReceiver)
                .tabItem{
                    Label("Settings", systemImage: "gearshape.circle")
                }
    

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
