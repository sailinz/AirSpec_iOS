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
    
    @State private var isSurvey = true
    let application = UIApplication.shared
    let secondAppPath = "cozie://"
    
    
    var body: some View {
        ZStack{
            TabView{
                HomeView()
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
            .blur(radius: isSurvey ? 20 : 0)
            
            if(isSurvey){
                VStack{
                    /// how to open another app: https://www.youtube.com/watch?v=xJU634A14u4 
                    Text("Fill in a survey to unlock the AirSpec App")
                    
                    Button(action:{
                        withAnimation{
                            let appUrl = URL(string:secondAppPath)!
                            if application.canOpenURL(appUrl){
                                application.open(appUrl)
                            }else{
                                print("cannot find cozie app")
                            }
                            
                            isSurvey.toggle()
                        }
                    }) {
                        Text("Go to Cozie")
                        .font(.system(.subheadline) .weight(.semibold))
                        .foregroundColor(.white)
                    }
                    .frame(width: 140)
                    .padding(.all,5)
                    .background(.pink)
                    .clipShape(Capsule())
                }
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
