//
//  WatchSurveyComfyView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZHONG Sailin on 03.03.23.
//

import SwiftUI
import WatchConnectivity

struct WatchSurveyComfyView: View {
    let comfyColor:Color = .mint
    let uncomfyColor:Color = .pink
    @State var surveyRecordIndex: Int = 0
    @Binding var eyeCalibration:Bool
    @Binding var isComfyVote: Bool
    @Binding var showSurvey: Bool

    @ObservedObject var surveyStatusToPhone:SensorData
    
    var body: some View {
        
        
        ZStack{
            if eyeCalibration{
                BlinkView(eyeCalibration: $eyeCalibration)
            }else{
                if(isComfyVote){
                    VStack{
                        Spacer()
                            .frame(height: 30)
                        Text("How are you feeling now?")
                        Spacer()
                            .frame(height: 10)
                        HStack{
                            Button(action:{
                                print("isSurvey: \(showSurvey)")
                                do{
                                    //                        try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(-2), choice: "not comfy")
                                    RawDataViewModel.addSurveyDataToRawData(qIndex: -2, qChoice: "not comfy", qGroupIndex: UInt32(surveyRecordIndex), timestampUnix: Date())
                                    
                                    surveyStatusToPhone.updateSurveyStatus(isSurveyDone: true)
                                    
                                    isComfyVote = false
                                }catch{
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
                                        Text("Not comfy")
                                            .font(.system(.subheadline) .weight(.semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                                .frame(width: 15)
                            
                            Button(action:{
                                print("isSurvey: \(showSurvey)")
                                do{
                                    
                                    //                        try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(-2), choice: "comfy")
                                    RawDataViewModel.addSurveyDataToRawData(qIndex: -2, qChoice: "comfy", qGroupIndex: UInt32(surveyRecordIndex), timestampUnix: Date())
                                    surveyStatusToPhone.updateSurveyStatus(isSurveyDone: true)
                                    isComfyVote = false
                                }catch{
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
                                        Text("Comfy")
                                            .font(.system(.subheadline) .weight(.semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        /// allow user to close the survey
                        HStack{
                            
                            Button(action:{
                                withAnimation{
                                    RawDataViewModel.addMetaDataToRawData(payload: "go to main view on watch", timestampUnix: Date(), type: 1) 
                                    showSurvey = false
                                    isComfyVote = false
                                    
                                }
                            }){
                                Image(systemName: "xmark.circle")
                                    .font(.system(size:20, weight:.bold))
                                    .foregroundColor(.pink)
                            }
                            .clipShape(Circle())
                            
                            Spacer()
                                .frame(width: 10)
                           
//                            Button(action:{
//
//                                do{
//
//                                    surveyStatusToPhone.updateEyeCalibrationStatus(isEyeCalibrationDone: true)
//
//
//                                }catch{
//                                    print("Error triggering eye calibration: \(error.localizedDescription)")
//                                }
//
//                            }){
//                                Image(systemName: "eyeglasses")
//                                    .font(.system(size:20, weight:.bold))
//                                    .foregroundColor(.white)
//                            }
//                            .clipShape(Circle())
                            
                            Button(action:{
                                surveyStatusToPhone.updateEyeCalibrationStatus(isEyeCalibrationDone: true)
                                eyeCalibration = true
                            }){
                                Image(systemName: "eye.circle")
                                    .font(.system(size:20, weight:.bold))
                                    .foregroundColor(.mint)
                            }
                            .clipShape(Circle())
                            
                        }
                        
                    }
                }else{
                    WatchSurveyQuestionView(showSurvey: $showSurvey)
                }
            }
        }
        .onAppear{
            showSurvey = true
            isComfyVote = true
            eyeCalibration = false
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

//struct WatchSurveyComfyView_Previews: PreviewProvider {
//    @State static var showSurvey = true
//    @State static var isComfyVote = true
//
//    static var previews: some View {
//        WatchSurveyComfyView(isComfyVote: $isComfyVote, showSurvey: $showSurvey, surveyStatusToPhone: SensorData)
//    }
//}

