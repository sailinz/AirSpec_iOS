//
//  SwiftUIView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 16.01.23.
//

import SwiftUI

struct SelfLoggingView: View {
    @Binding var show: Bool
    let comfyColor:Color = .mint
    let uncomfyColor:Color = .pink
    @State private var comments: String = ""
    @State var surveyButton: Bool = false
    @State var isComfySelected:Bool = false
    @State var isUncomfySelected:Bool = false
    @State private var vStackHeight: CGFloat = 0
    
    
//    let userID = UserDefaults.standard.double(forKey: "user_id")
    @State var surveyRecordIndex: Int = 0
//    @StateObject var surveyData = SurveyDataViewModel()
//    @EnvironmentObject var surveyData: SurveyDataViewModel
    @EnvironmentObject private var receiver: BluetoothReceiver
    
    
    var body: some View {
        
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)){
            if(surveyButton){
                SurveyQuestionView(showSurvey: $surveyButton)
                    .padding(.vertical, 25)
                    .padding(.horizontal,30)
                    .background(BlurView())
                    .cornerRadius(25)
            }else{
                
                VStack(spacing:25){
                    HStack{
                        ScrollView(){
                            VStack{
                                Text("How are you feeling now?")
                                    .multilineTextAlignment(.center)
                                Spacer()
                                    .frame(height: 20)
                                HStack{
                                    Button(action:{
                                        isComfySelected = false
                                        isUncomfySelected = true
                                        do{
                                            var secondsBetweenDates = Double(receiver.greenHoldTime + 12)
                                            if let prevNotificationTime = UserDefaults.standard.object(forKey: "prevNotificationTime") as? Date{
                                                secondsBetweenDates = Date().timeIntervalSince(prevNotificationTime)
                                            }
                                            
                                            try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(-2), choice: "not comfy")
                                            RawDataViewModel.addSurveyDataToRawData(qIndex: -2, qChoice: "not comfy", qGroupIndex: UInt32(surveyRecordIndex), timestampUnix: Date())
                                            
                                            receiver.notificationTimer?.cancel()
                                            receiver.notificationTimer = nil
                                            
                                            
                                            if(!receiver.isBlueGreenSurveyDone){
                                                RawDataViewModel.addMetaDataToRawData(payload: "Reaction time: \(secondsBetweenDates); Time now: \(Date()); PrevNotification: \(UserDefaults.standard.object(forKey: "prevNotificationTime")); survey received from phone; reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                                                
                                                receiver.blueGreenLight(isEnable: false)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3)  { /// wait for 3 sec
                                                    receiver.setBlue()
                                                }
                                            }else{
                                                RawDataViewModel.addMetaDataToRawData(payload: "Survey received from phone (without blue-green transition); reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                                            }
                                            
                                            
                                        }catch{
                                            RawDataViewModel.addMetaDataToRawData(payload: "Error saving survey data from phone: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
                                            print("Error saving survey data: \(error.localizedDescription)")
                                        }
                                    }){
                                        ZStack{
                                            VStack{
                                                ZStack{
                                                    Circle()
                                                        .frame(width:42, height:42)
                                                        .foregroundColor(uncomfyColor)
                                                        .shadow(color: uncomfyColor, radius: 2, x: 0, y: 2)
                                                    Image("not_comfy")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(.white)
                                                        .frame(width: 20, height:20)
                                                }
                                                .scaleEffect(isUncomfySelected ? 1.2 : 1)
                                                
                                                Text("Not comfy")
                                                    .font(.system(.subheadline) .weight(.semibold))
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                        .frame(width: 20)
                                    
                                    Button(action:{
                                        isComfySelected = true
                                        isComfySelected = true
                                        isUncomfySelected = false
                                        do{
                                            var secondsBetweenDates = Double(receiver.greenHoldTime + 12)
                                            if let prevNotificationTime = UserDefaults.standard.object(forKey: "prevNotificationTime") as? Date{
                                                secondsBetweenDates = Date().timeIntervalSince(prevNotificationTime)
                                            }
                                            
                                            try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(-2), choice: "comfy")
                                            RawDataViewModel.addSurveyDataToRawData(qIndex: -2, qChoice: "comfy", qGroupIndex: UInt32(surveyRecordIndex), timestampUnix: Date())
                                            
                                            receiver.notificationTimer?.cancel()
                                            receiver.notificationTimer = nil
                                            
                                            
                                            if(!receiver.isBlueGreenSurveyDone){
                                                RawDataViewModel.addMetaDataToRawData(payload: "Reaction time: \(secondsBetweenDates); Time now: \(Date()); PrevNotification: \(UserDefaults.standard.object(forKey: "prevNotificationTime")); survey received from phone; reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                                                
                                                receiver.blueGreenLight(isEnable: false)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3)  { /// wait for 3 sec
                                                    receiver.setBlue()
                                                }
                                            }else{
                                                RawDataViewModel.addMetaDataToRawData(payload: "Survey received from phone (without blue-green transition); reset LED to blue; push notification of survey suspended", timestampUnix: Date(), type: 2)
                                            }
                                            
                                            
                                            
                                        }catch{
                                            RawDataViewModel.addMetaDataToRawData(payload: "Error saving survey data from phone: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
                                            print("Error saving survey data: \(error.localizedDescription)")
                                        }
                                    }){
                                        ZStack{
                                            VStack{
                                                ZStack{
                                                    Circle()
                                                        .frame(width:42, height:42)
                                                        .foregroundColor(comfyColor)
                                                        .shadow(color: comfyColor, radius: 2, x: 0, y: 2)
                                                    Image("comfy")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(.white)
                                                        .frame(width: 20, height:20)
                                                }
                                                .scaleEffect(isComfySelected ? 1.2 : 1)
                                                
                                                Text("comfy")
                                                    .font(.system(.subheadline) .weight(.semibold))
                                                    .foregroundColor(comfyColor)
                                            }
                                        }
                                    }
                                }
                                
                                
                                Spacer()
                                    .frame(height: 40)
                                
                                
                                Text("Have time for a 30s survey?")
                                    .multilineTextAlignment(.center)
                                
                                Button(action:{
                                    ///go to the survey view
                                    surveyButton.toggle()
                                }
                                ) {
                                    Text("Start survey")
                                        .font(.system(.subheadline) .weight(.semibold))
                                        .foregroundColor(.white)
                                    Image(systemName: "pencil.line")
                                        .foregroundColor(.white)
                                }
                                .padding(.all,10)
                                .background(.pink.opacity(0.6))
                                .clipShape(Capsule())
                                
                                Spacer()
                                    .frame(height: 40)
                                Text("Any comments?")
                                //                        Spacer()
                                //                            .frame(height: 20)
                                
                                TextEditor(
                                    //                                    " Enter text or voice-to-text here",
                                    text: $comments
                                    //                                    axis:.vertical
                                )
                                .padding(5)
                                .frame(minHeight: 40, maxHeight: 40 * 2)
                                .frame(width: 250)
                                .background(RoundedRectangle(cornerRadius: 15).fill(Color.gray).opacity(0.1))
                                .multilineTextAlignment(.leading)
                                .onTapGesture {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                //                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pink,lineWidth: 1))
                                
                                
                                Button(action:{
                                    ///submit data
                                    do{
                                        
                                        if self.comments != "" {
                                            try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(-1), choice: self.comments)
                                            print("comments: \(self.comments)")
                                            RawDataViewModel.addSurveyDataToRawData(qIndex: -1, qChoice: self.comments, qGroupIndex: UInt32(surveyRecordIndex), timestampUnix: Date())
                                        }
                                        
                                        
                                    }catch{
                                        RawDataViewModel.addMetaDataToRawData(payload: "Error saving survey data: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
                                        print("Error saving survey data: \(error.localizedDescription)")
                                    }
                                    
                                    withAnimation{
                                        show.toggle()
                                    }
                                    
                                }
                                ) {
                                    Text("Done")
                                        .font(.system(.subheadline) .weight(.semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.all,10)
                                .background(.pink.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(.top, 30)
                                
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        self.vStackHeight = geometry.size.height
                                    }
                                }
                            )
                            
                        }
                        .frame(maxHeight: vStackHeight > UIScreen.main.bounds.height ? .infinity : vStackHeight)
                        
                       
                        
                    }
                }
                .padding(.vertical, 25)
                .padding(.horizontal,30)
                .background(BlurView())
                .cornerRadius(25)
            }
            
            
            /// close the sruvey
            Button(action:{
                withAnimation{
                    show.toggle()
                    /// also save the data here in case people accidentally close it after writing the comments
                }
            }){
                Image(systemName: "xmark.circle")
                    .font(.system(size:28, weight:.bold))
                    .foregroundColor(.pink)
            }
            .padding(5)
        }
        .background(
            Color.white.opacity(0.35)
        )
        
        .onAppear{
            isComfySelected = false
            isUncomfySelected = false
            print("survey appear")
            if UserDefaults.standard.integer(forKey: "survey_record_index") == 0 {
                UserDefaults.standard.set(1, forKey: "survey_record_index")
                surveyRecordIndex = 1
            }else{
                surveyRecordIndex = UserDefaults.standard.integer(forKey: "survey_record_index") + 1
                UserDefaults.standard.set(surveyRecordIndex, forKey: "survey_record_index")
                
            }
        }
        
        
    }
}

struct SelfLoggingView_Previews: PreviewProvider {
    @State static var show = true
    
    static var previews: some View {
        SelfLoggingView(show: $show)
    }
}


