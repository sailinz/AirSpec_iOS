//
//  WatchSurveyComfyView.swift
//  AirSpec_iOS Watch App
//
//  Created by ZHONG Sailin on 03.03.23.
//

import SwiftUI

struct WatchSurveyQuestionView: View {
    
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
    @Binding var showSurvey: Bool
    
    
    var body: some View {
        VStack{
            ScrollViewReader { scrollView in
                ScrollView{
                    VStack {
                        var currentQuestionItem = questions.filter{ $0.currentQuestion == nextQuestion}.first ?? questions[0]
                        Text(currentQuestionItem.title)
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding()
                            .id("question")
                        
                        ForEach(Array(currentQuestionItem.options.enumerated()), id: \.offset) { (index, option) in
                            
                            Button(action: {
                                
                                // button action here
                                if(!currentQuestionItem.multiChoice){
                                    self.currentAnswer = index
                                    do{
                                        /// save to coredata
                                        //                                try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(nextQuestion), choice: "\(currentAnswer.description)")
                                        RawDataViewModel.addSurveyDataToRawData(qIndex: Int32(nextQuestion), qChoice: "\(currentAnswer.description)", qGroupIndex: UInt32(UserDefaults.standard.integer(forKey: "survey_record_index")), timestampUnix: Date())
                                    }catch{
                                        print("Error saving survey data: \(error.localizedDescription)")
                                    }
                                    
                                    
                                    /// end of the survey
                                    if(currentQuestionItem.nextQuestion[0] == 999){
                                        print("survey record index: \(UserDefaults.standard.integer(forKey: "survey_record_index"))")
//                                        self.uploadToServer()
                                        showSurvey = false
                                    }
                                    
                                    self.currentQuestion = currentQuestionItem.currentQuestion
                                    self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                                    
                                }else{
                                    self.currentAnswer = index /// make sure all the multiple answers as the same next question
                                    self.currentAnswers.append(index)
                                    
                                    if self.currentAnswersDisplay.contains(index){
                                        currentAnswersDisplay.removeAll { $0 == index }
                                    }else{
                                        self.currentAnswersDisplay.append(index)
                                    }
                                    
                                    
                                    
                                }
                            }) {
                                
                                HStack{
                                    Image(currentQuestionItem.icons[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .colorMultiply(.pink.opacity(0.7))
                                        .frame(maxWidth: 20, alignment: .leading)
                                    Text(option)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .background( .pink.opacity((currentQuestionItem.multiChoice && currentAnswersDisplay.contains(index)) ? 0.7 : 0.2)
                            )
                            .clipShape(Capsule())
                        }
                        
                        if(currentQuestionItem.multiChoice){
                            Button(action: {
                                // button action here
                                do{
                                    /// save to coredata
                                    //                            try SurveyDataViewModel.addSurveyData(timestamp: Date(), question: Int16(nextQuestion), choice: "\(currentAnswers.description)")
                                    RawDataViewModel.addSurveyDataToRawData(qIndex: Int32(nextQuestion), qChoice: "\(currentAnswers.description)", qGroupIndex: UInt32(UserDefaults.standard.integer(forKey: "survey_record_index")), timestampUnix: Date())
                                }catch{
                                    print("Error saving survey data: \(error.localizedDescription)")
                                }
                                
                                /// something hardcoded - but the logic should be done properly!!!!
                                if nextQuestion == 1{ /// the question about change
                                    if currentAnswersDisplay.contains(2){ /// visual comfort
                                        currentAnswer = 2
                                    }else{
                                        currentAnswer = 1 /// any other answers that does not include visual comfort
                                    }
                                }
                                
                                self.currentQuestion = currentQuestionItem.currentQuestion
                                self.nextQuestion = currentQuestionItem.nextQuestion[currentAnswer]
                                self.currentAnswer = 999 /// reset
                                self.currentAnswers = [] /// reset
                                self.currentAnswersDisplay = []
                                
                                
                            }) {
                                HStack{
                                    Text("Next")
                                        .foregroundColor(.white.opacity(currentQuestionItem.nextQuestion[0] == 999 ? 0.2: 1))
                                    
                                }
                                
                            }
                            .frame(width:80)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        
                    }
                }
                .onChange(of: nextQuestion) { _ in
                    withAnimation {
                        scrollView.scrollTo("question", anchor: .top)
                    }
                }
                    
            }
        }
        
    }
    
    
    
}




struct WatchSurveyQuestionView_Previews: PreviewProvider {
    @State static var showSurvey = true
    static var previews: some View {
        WatchSurveyQuestionView(showSurvey: $showSurvey)
    }
}

