//
//  SurveyQuestionView.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 25.01.23.
//  Modified from

//  InterfaceController.swift
//  Cozie WatchKit Extension
//
//  Created by Federico Tartarini on 25/5/20.
//  Copyright © 2020 Federico Tartarini. All rights reserved

import SwiftUI
import Foundation
import CoreLocation

struct SurveyQuestionView: View {
    // initialize variables
    @State var stopButton: Bool = false
    @State var backButton: Bool = false
    @State var questionTitle = ""
    @State var questions =  questionFlows[0].questions ///[Question]()
    @State var answers = [Answer]()  // it stores the answer after user as completed Cozie
//    @State var tmpResponses: [String: String] = [:]  // it temporally stores user's answers
    @State var questionsDisplayed = [0] // this holds in memory which questions was previously shown
//    @State var voteLog = 0
    @State var currentAnswer = 999 /// single choice
    @State var currentAnswers = [Int]() /// multiple choices
    @State var currentAnswersDisplay = [Int]() /// multiple choices
    @State var currentQuestion = 11
    @State var nextQuestion = 11
    @State private var vStackHeight: CGFloat = 0
//    @State var backPressed: Bool = false
    @State var questionHistory: [Int] = []
    @State var answerHistory = [Int32: String]()
    
    @Binding var showSurvey: Bool
    @Environment(\.colorScheme) var colorScheme
    
    
//    let userID = UserDefaults.standard.double(forKey: "user_id")
//    @StateObject var surveyData = SurveyDataViewModel()
//    @EnvironmentObject var surveyData: SurveyDataViewModel
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical){
                VStack {
                    var currentQuestionItem = questions.filter{ $0.currentQuestion == nextQuestion}.first ?? questions[0]
                    //back button; only appears after the first question
                    if (currentQuestionItem.currentQuestion != 11)
                        {Button(action: {
                            self.nextQuestion = self.questionHistory.removeLast()
                            self.answerHistory.removeValue(forKey: Int32(self.nextQuestion))
                            self.currentAnswers = [] /// reset
                            self.currentAnswersDisplay = [] //reset
                        }){
                            Text("Back")
                                .font(.system(.subheadline) .weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.all, 10)
                        .background(.pink.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.trailing, 250)
                    }
                    Text(currentQuestionItem.title)
                        .font(.title3)
                        .id("question")
                        .foregroundColor(.primary)
                        .padding()
                    
                    
                    //            Text("userID: \(userID)")
                    //            Text("current question: \(currentQuestion)")
                    //            Text("next question: \(nextQuestion)")
                    //            Text("current answer: \(currentAnswer)")
                    //            Text("current answer: \(currentAnswers.description)")
                    //            Text("foresee next question: \(currentQuestionItem.nextQuestion[0])")
                    
                    ForEach(Array(currentQuestionItem.options.enumerated()), id: \.offset) { (index, option) in
                        
                        Button(action: {
                            
                            // button action here
                            if(!currentQuestionItem.multiChoice){
                                self.currentAnswer = index
                                self.answerHistory[Int32(nextQuestion)] = "\(currentAnswer.description)"
                                
                                /*do{
                                    self.answerHistory[Int32(nextQuestion)] = "\(currentAnswer.description)"
                                    /// save to coredata
                                    try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(nextQuestion), choice: "\(currentAnswer.description)")
                                    RawDataViewModel.addSurveyDataToRawData(qIndex: Int32(nextQuestion), qChoice: "\(currentAnswer.description)", qGroupIndex: UInt32(UserDefaults.standard.integer(forKey: "survey_record_index")), timestampUnix: Date())
                                }catch{
                                    print("Error saving survey data: \(error.localizedDescription)")
                                }*/
                                
                                
                                if(currentQuestionItem.nextQuestion[0] == 999){
                                    print("survey record index: \(UserDefaults.standard.integer(forKey: "survey_record_index"))")
                                    showSurvey.toggle()
                                    for (q_index, q_choice) in answerHistory{
                                        print(q_index, q_choice)
                                        do{
                                            /// save accumulated responses to coredata
                                            try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(q_index), choice: q_choice)
                                            RawDataViewModel.addSurveyDataToRawData(qIndex: Int32(q_index), qChoice: q_choice, qGroupIndex: UInt32(UserDefaults.standard.integer(forKey: "survey_record_index")), timestampUnix: Date())
                                            usleep(1000000)
                                            
                                        }catch{
                                            
                                            //RawDataViewModel.addMetaDataToRawData(payload: "Error saving survey data: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
                                            print("Error saving survey data: \(error.localizedDescription)")
                                        }
                                        
                                    }
                                }
                                
                                self.questionHistory.append(currentQuestionItem.currentQuestion)
                                self.currentQuestion = currentQuestionItem.currentQuestion
                                self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                            }else{
                                //multiple choice
                                self.currentAnswer = index /// make sure all the multiple answers as the same next question
                                //self.currentAnswers.append(index)
                                
                                if self.currentAnswersDisplay.contains(index){
                                    currentAnswersDisplay.removeAll { $0 == index }
                                }else{
                                    self.currentAnswersDisplay.append(index)
                                }
                                self.currentAnswers = currentAnswersDisplay
                                
                                
                            }
                            
                            
                            
                        }) {
                            
                            HStack{
                                Image(currentQuestionItem.icons[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .colorMultiply(.pink.opacity(0.7))
                                    .frame(maxWidth: 20, alignment: .leading)
                                Text(option)
                                    .foregroundColor(colorScheme == .light ? .black: .white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width:200)
                        .padding(.all,10)
                        .background( .pink.opacity((currentQuestionItem.multiChoice && currentAnswersDisplay.contains(index)) ? 0.5 : 0.2)
                        )   ///(.pink.opacity(index == self.currentAnswer ? 0.5 : 0.2))
                        .clipShape(Capsule())
                    }
                    
                    if(currentQuestionItem.multiChoice){
                        Button(action: {
                            // button action here
                            self.answerHistory[Int32(nextQuestion)] = "\(currentAnswers.description)"
                            /*do{
                                self.answerHistory[Int32(nextQuestion)] = "\(currentAnswers.description)"
                                /// save to coredata
                                try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(nextQuestion), choice: "\(currentAnswers.description)")
                                RawDataViewModel.addSurveyDataToRawData(qIndex: Int32(nextQuestion), qChoice: "\(currentAnswers.description)", qGroupIndex: UInt32(UserDefaults.standard.integer(forKey: "survey_record_index")), timestampUnix: Date())
                            }catch{
                                RawDataViewModel.addMetaDataToRawData(payload: "Error saving survey data: \(error.localizedDescription)", timestampUnix: Date(), type: 2)
                                print("Error saving survey data: \(error.localizedDescription)")
                            }*/
                            
                            
                            /// as long as user thought about visual comfort, just ask the eye fatigue question
                            if nextQuestion == 1{ /// the question about change
                                if currentAnswersDisplay.contains(2){ /// visual comfort
                                    currentAnswer = 2
                                }else{
                                    currentAnswer = 1 /// any other answers that does not include visual comfort
                                }
                            }

                            
                            self.questionHistory.append(currentQuestionItem.currentQuestion)
                            self.currentQuestion = currentQuestionItem.currentQuestion
                            self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                            self.currentAnswer = 999 /// reset
                            self.currentAnswers = [] /// reset
                            self.currentAnswersDisplay = []
                            ///
                            
                            
                            
                        }) {
                            HStack{
                                Text("Next")
                                    .foregroundColor(.black)
                                    .foregroundColor(.black.opacity(currentQuestionItem.nextQuestion[0] == 999 ? 0.2: 1))
                            }
                        }
                        .frame(width:85)
                        .padding(.all,10)
                        .background(.pink.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            self.vStackHeight = geometry.size.height
                        }
                        Color.clear.onChange(of: geometry.size.height) { newValue in
                            if vStackHeight != newValue {
                                vStackHeight = newValue
                            }
                        }
                    }
                )
                
            }
            .frame(maxHeight: vStackHeight > UIScreen.main.bounds.height ? .infinity : vStackHeight)
            .onChange(of: nextQuestion) { _ in
                withAnimation {
                    scrollView.scrollTo("question", anchor: .top)
                }
            }
            
        }
            
        
    }
    
    
}

struct SurveyQuestionView_Previews: PreviewProvider {
    @State static var showSurvey = true
    static var previews: some View {
        SurveyQuestionView(showSurvey: $showSurvey)
    }
}
