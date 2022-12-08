//
//  Home.swift
//  AirSpec_Watch Watch App
//
//  Created by ZHONG Sailin on 03.11.22.
//  developer.apple.com/videos/play/wwdc2021/10005

import SwiftUI
import Foundation
import WatchConnectivity

struct WatchHome : View {
    
    /// This delegate manages the life cycle of the watchOS app.
//    @WKExtensionDelegateAdaptor var delegate: ExtensionDelegate
    var body: some View {
        NavigationView {
            VStack {
                Text("Home")
                    .font(Font.headline.weight(.bold))
                NavigationLink(destination: SensorReadingView()) {
                    Text("Glasses' data")
                }
                
//                NavigationLink(destination: GlassesTestView().environmentObject(delegate.bluetoothReceiver)) {
//                    Text("Test glasses BLE")
//                }
                
                
//                NavigationLink(destination: FlowIOTestView()) {
//                    Text("Flow IO Test control")
//                }
            }
        }
    }
}


struct WatchHome_Previews: PreviewProvider {
    static var previews: some View {
        WatchHome()
    }
}

