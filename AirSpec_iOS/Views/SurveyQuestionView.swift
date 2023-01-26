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

// temp dictionary to store the answers
struct Answer: Codable {
//    let timestamp_start: String
//    let timestamp_end: String
//    let heart_rate: [String: Int]
//    let sound_pressure: [String: Int]
//    let id_participant: String
//    let id_experiment: String
//    let id_device: String
//    let timestamp_location: String
//    let latitude: Double
//    let longitude: Double
    let responses: [String: String]
//    let vote_count: Int
//    let body_mass: Double
}

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
    @State var currentQuestion = 0
    @State var nextQuestion = 0
//    @State var backPressed: Bool = false
    
    @Binding var showSurvey: Bool
    
    
    
    var body: some View {
        VStack {
            var currentQuestionItem = questions.filter{ $0.currentQuestion == nextQuestion}.first ?? questions[0]
            Text(currentQuestionItem.title)
                .font(.title3)
                .foregroundColor(.primary)
                .padding()
            
//            Text("current question: \(currentQuestion)")
//            Text("next question: \(nextQuestion)")
//            Text("current answer: \(currentAnswer)")
//            Text("foresee next question: \(currentQuestionItem.nextQuestion[0])")
            
            ForEach(Array(currentQuestionItem.options.enumerated()), id: \.offset) { (index, option) in
                
                Button(action: {
                    
                    // button action here
                    if(!currentQuestionItem.multiChoice){
                        self.currentAnswer = index
                        
                        if(currentQuestionItem.nextQuestion[0] == 999){
                            showSurvey.toggle()
                        }
                        
                        self.currentQuestion = currentQuestionItem.currentQuestion
                        self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                    }else{
                        self.currentAnswer = index /// make sure all the multiple answers as the same next question
                        self.currentAnswers.append(index)
                    }
                    
                    
                    
                }) {
                    
                    HStack{
                        Image(currentQuestionItem.icons[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .colorMultiply(.pink.opacity(0.7))
                            .frame(maxWidth: 20, alignment: .leading)
                        Text(option)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width:200)
                .padding(.all,10)
                .background( .pink.opacity((currentQuestionItem.multiChoice && currentAnswers.contains(index)) ? 0.5 : 0.2)
                )   ///(.pink.opacity(index == self.currentAnswer ? 0.5 : 0.2))
                .clipShape(Capsule())
            }
            
            if(currentQuestionItem.multiChoice){
                Button(action: {
                    // button action here

                    self.currentQuestion = currentQuestionItem.currentQuestion
                    self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                    self.currentAnswer = 999 /// reset
                    self.currentAnswers = [] /// reset

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
            
//            Spacer()
//                .frame(height: 30)
//            HStack{
//                Button(action: {
//                    if(nextQuestion != 0){
//                        self.nextQuestion = self.currentQuestion
//                    }
//                }) {
//                    HStack{
//                        Text("Back")
//                            .foregroundColor(.black.opacity(nextQuestion == 0 ? 0.2: 1))
//                    }
//                }
//                .frame(width:85)
//                .padding(.all,10)
//                .background(.pink.opacity(0.2))
//                .clipShape(Capsule())
//
//                Button(action: {
//                    // button action here
//
//                    self.currentQuestion = currentQuestionItem.currentQuestion
//                    self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
//                    self.currentAnswer = 999 /// reset
//
//                }) {
//                    HStack{
//                        Text("Next")
//                            .foregroundColor(.black)
//                            .foregroundColor(.black.opacity(currentQuestionItem.nextQuestion[0] == 999 ? 0.2: 1))
//                    }
//                }
//                .frame(width:85)
//                .padding(.all,10)
//                .background(.pink.opacity(0.2))
//                .clipShape(Capsule())
//            }
                
            
        }
        .onAppear{
            
            
            /// get participant ID from user defaults
            // ...
            
//            defineQuestions()
            
            
        }
        

    }
    
//    func defineQuestions() {
//        self.questions = questionFlows[0].questions
//
//        self.questions += [Question(
//            title: "Thank you.",
//            identifier: "end",
//            options: ["Submit survey"],
//            icons: ["submit"],
//            nextQuestion: [999])]
//    }
    
}

struct SurveyQuestionView_Previews: PreviewProvider {
    @State static var showSurvey = true
    static var previews: some View {
        SurveyQuestionView(showSurvey: $showSurvey)
    }
}
