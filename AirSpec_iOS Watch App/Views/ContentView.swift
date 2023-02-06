//
//  ContentView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZHONG Sailin on 20.11.22.
//


import SwiftUI
import CoreBluetooth

struct ContentView: View {
//    let viewModel = ProgramViewModel(connectivityProvider: ConnectionProvider())
    var body: some View {
        WatchHomeView()
//        SensorReadingView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
