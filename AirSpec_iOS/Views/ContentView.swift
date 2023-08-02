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
    
//    @State private var isSurvey = true
//    let application = UIApplication.shared
//    let secondAppPath = "cozie://"
    
    @State private var feedbackButton = false
    @Environment(\.scenePhase) var scenePhase
    var timer: DispatchSourceTimer? = DispatchSource.makeTimerSource()
//    let updateFrequence = 60 * 1 /// seconds
    
    @Binding var flags : [Bool]
    var body: some View {
        ZStack(alignment: .top){
            TabView{
                HomeView(flags: flags).environmentObject(delegate.bluetoothReceiver)
                    .tabItem{
                        Label("Home", systemImage: "heart.circle.fill")
                    }
                
                MyDataView(flags: $flags)
                    .tabItem{
                        Label("My data", systemImage: "person.crop.circle")
                    }
                
                SettingView().environmentObject(delegate.bluetoothReceiver)
                    .tabItem{
                        Label("Settings", systemImage: "gearshape.circle")
                    }

            }
//            .blur(radius: isSurvey ? 20 : 0)
//
//            if(isSurvey){
//                VStack{
//                    /// how to open another app: https://www.youtube.com/watch?v=xJU634A14u4
//                    Text("Fill in a survey to unlock the AirSpec App")
//
//                    Button(action:{
//                        withAnimation{
//                            let appUrl = URL(string:secondAppPath)!
//                            if application.canOpenURL(appUrl){
//                                application.open(appUrl)
//                            }else{
//                                print("cannot find cozie app")
//                            }
//
//                            isSurvey.toggle()
//                        }
//                    }) {
//                        Text("Go to Cozie")
//                        .font(.system(.subheadline) .weight(.semibold))
//                        .foregroundColor(.white)
//                    }
//                    .frame(width: 140)
//                    .padding(.all,5)
//                    .background(.pink)
//                    .clipShape(Capsule())
//                }
//            }
            
            Button(action:{
                withAnimation{
                    feedbackButton.toggle()
                }
            }){
                ZStack{
                    Circle()
                        .frame(width:26, height:26)
                        .foregroundColor(.pink)
                    Image(systemName: "square.and.pencil.circle")
                        .frame(width:26, height:26)
                        .foregroundColor(.white)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            .padding(.bottom, 30)
            .padding(.top, 50)
            
            
            if feedbackButton{
                SelfLoggingView(show: $feedbackButton).environmentObject(delegate.bluetoothReceiver)
            }
        }
//        .onAppear{
//            timer?.schedule(deadline: .now() + .seconds(5), repeating: .seconds(updateFrequence))
//            timer?.setEventHandler {
////                self.isUploadToServer = true
//                DispatchQueue.global().async {
//                    uploadToServer()
//                }
//
//    //            self.countUpdateFrequency = self.countUpdateFrequency + 1
//    //            if self.countUpdateFrequency == 5 {
//    //                self.countUpdateFrequency = 0
//    //                DispatchQueue.main.asyncAfter(deadline: .now() + 20)  { /// wait for 3 sec
//    //                    self.storeLongTermData()
//    //                }
//    //            }
//
//
//            }
//            timer?.resume()
//        }
//        .onChange(of: scenePhase) { newPhase in
//            
//            if newPhase == .inactive {
//                print("Inactive")
//                RawDataViewModel.addMetaDataToRawData(payload: "phone inactive", timestampUnix: Date(), type: 1)
//            } else if newPhase == .active {
//                print("Active")
//                RawDataViewModel.addMetaDataToRawData(payload: "phone active", timestampUnix: Date(), type: 1)
//            } else if newPhase == .background {
//                print("Background")
//                RawDataViewModel.addMetaDataToRawData(payload: "phone background", timestampUnix: Date(), type: 1)
//            }
//            
//        }
        
    }
    
//    func uploadToServer() {
//        print("try to upload to server")
//        DispatchQueue.global().async {
//            DispatchQueue.global().sync {
//                // https://stackoverflow.com/questions/42772907/what-does-main-sync-in-global-async-mean
//                
//                let sem = DispatchSemaphore(value: 0)
//                
//                while true {
//                    do {
//                        let (data, onComplete) = try RawDataViewModel.fetchData()
//                        if data.isEmpty {
////                            sem.signal()
////                            self.storeLongTermData()
////                            sem.wait()
//                            print("sent all packets")
//                            
//                            RawDataViewModel.addMetaDataToRawData(payload: "Sent all packets", timestampUnix: Date(), type: 7)
//                            try onComplete()
////                            self.isUploadToServer = false
////                            self.migrateFromTempRawToRaw()
//                            
//                            
//                            
//                            return
//                        }
//                        
//                        var err: Error?
//                        
//                        try Airspec.send_packets(packets: data, auth_token: AUTH_TOKEN) { error in
//                            err = error
//                            sem.signal()
//                        }
//                        
//                        sem.wait()
//                        
//                        if let err = err {
//                            throw err
//                        } else {
//                            try onComplete()
//                        }
//                    } catch {
//                        print("cannot upload the data to the server: \(error)")
//                        //                        RawDataViewModel.addMetaDataToRawData(payload: "cannot upload the data to the server: \(error)", timestampUnix: Date(), type: 2)
//                        break
//                    }
//                }
//                
//            }
//        }
//    }
//    
//    
//    
    
        
}

struct ContentView_Previews: PreviewProvider {
    struct ContentViewWrapper: View {
            @State var flags : [Bool] = Array(repeating: false, count: 12)

            var body: some View {
                ContentView(flags: $flags)
            }
        }
    static var previews: some View {
        ContentViewWrapper()
    }
}
