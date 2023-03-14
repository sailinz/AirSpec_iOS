//
// Created by Federico Tartarini on 11/5/22.
// Copyright (c) 2022 Federico Tartarini. All rights reserved.
//

import Foundation

struct Question: Codable, Hashable {
    let currentQuestion: Int
    let title: String
    let identifier: String
    let options: Array<String>
    let icons: Array<String>
    let nextQuestion: Array<Int>
    let multiChoice:Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(currentQuestion)
    }

    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.currentQuestion == rhs.currentQuestion
    }
}

struct Flow: Codable {
    let title: String
    let questions: Array<Question>
}

let questionFlows = [
    Flow(title: "Attention and comfort", questions:[
//        Question(
//            currentQuestion: 0,
//            title: "How are you feeling",
//            identifier: "overall-comfort",
//            options: [
//                "Comfy",
//                "Not comfy",
//            ],
//            icons: [
//                "mood-good",
//                "mood-bad",
//            ],
//            nextQuestion: [
//                4,
//                1
//            ],
//            multiChoice: false
//        ),
        Question(
            currentQuestion: 1,
//            title: "What do you feel uncomfortable with? (Allow multiple answers)",
//            identifier: "discomfort-kind",
//            options: [
//                "Thermal",
//                "Air quality",
//                "Lighting",
//                "Noise",
//                "Mood",
//                "Others"
//            ],
//            icons: [
//                "thermal-privacy",
//                "air-quality-smelly",
//                "light-bright",
//                "noise-privacy",
//                "happy",
//                "other"
//            ],
            title: "Anything you'd like to change? (Allow multiple answers)",
            identifier: "discomfort-kind",
            options: [
                "Thermal",
                "Air quality",
                "Lighting",
                "Noise",
                "Mood",
                "Bodily condition (e.g., hungry)",
                "Others",
                "None"
            ],
            icons: [
                "thermal-privacy",
                "air-quality-smelly",
                "light-bright",
                "noise-privacy",
                "entertainmentß",
                "appearance",
                "other",
                "none-1"
            ],
            nextQuestion: [
                2,
                2,
                2,
                2,
                2,
                2,
                2,
                2
            ],
            multiChoice: true
        ),
        Question(
              currentQuestion: 2,
              title: "Which one(s) do you have control in your environment? (Allow multiple answers)",
              identifier: "control",
              options: [
                  "Thermal",
                  "Air quality",
                  "Lighting",
                  "Noise",
                  "None"
              ],
              icons: [
                  "thermal-privacy",
                  "air-quality-smelly",
                  "light-bright",
                  "noise-privacy",
                  "none-1"
              ],
              nextQuestion: [
                  4,
                  4,
                  4,
                  4,
                  4
              ],
              multiChoice: true
        ),
//        Question(
//              currentQuestion: 3,
//              title: "Thermally, what do you prefer now?",
//              identifier: "thermal-preference",
//              options: [
//                  "Cooler",
//                  "No change",
//                  "Warmer"
//              ],
//              icons: [
//                  "prefer-cooler",
//                  "no-change",
//                  "prefer-warmer"
//              ],
//              nextQuestion: [
//                  4,
//                  4,
//                  4
//              ],
//              multiChoice: false
//        ),
        Question(
              currentQuestion: 4,
              title: "Where are you?",
              identifier: "location",
              options:[
                  "Indoor - Office",
                  "Indoor - Class",
                  "Indoor - Home",
                  "Indoor - Other",
                  "Outdoor",
                  "Transportation"
              ],
              icons: [
                  "indoor-1",
                  "classroom",
                  "home",
                  "other",
                  "outdoor-1",
                  "Transportation"
              ],
              nextQuestion: [
                  5,
                  7,
                  7,
                  7,
                  7,
                  6
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 5,
              title: "What kind of office?",
              identifier: "location-office",
              options: [
                  "Individual",
                  "Small shared",
                  "Large open plan",
                  "Cubicles",
                  "Conference room"
              ],
              icons: [
                  "personal",
                  "shared",
                  "open-space",
                  "cubicles",
                  "conference-room"
              ],
              nextQuestion: [
                  7,
                  7,
                  7,
                  7,
                  7
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 6,
              title: "What kind of transport?",
              identifier: "location-transport",
              options:[
                  "Bus",
                  "Train",
                  "Car",
                  "Taxi",
                  "Other"
              ],
              icons: [
                  "bus",
                  "train",
                  "car",
                  "taxi",
                  "other"
              ],
              nextQuestion: [
                  7,
                  7,
                  7,
                  7,
                  7
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 7,
              title: "Alone or in a group?",
              identifier: "alone-group",
              options: [
                  "Alone",
                  "Group",
                  "Online group"
              ],
              icons: [
                  "alone",
                  "group",
                  "online"
              ],
              nextQuestion: [
                  8,
                  9,
                  9
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 8,
              title: "Category of activity?",
              identifier: "activity-category",
              options:[
                  "Focus",
                  "Leisure",
                  "Other"
              ],
              icons: [
                  "focus",
                  "leisure",
                  "other"
              ],
              nextQuestion: [
                  10,
                  10,
                  10
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 9,
              title: "Category of activity?",
              identifier: "activity-category",
              options: [
                  "Socialize",
                  "Collaborate",
                  "Learn",
                  "Other"
              ],
              icons: [
                  "socialize",
                  "collaborate",
                  "learn",
                  "other"
              ],
              nextQuestion: [
                  10,
                  10,
                  10,
                  10
              ],
              multiChoice: false
        ),
        Question(
               currentQuestion: 10,
               title: "Thank you.",
               identifier: "end",
               options: ["Submit survey"],
               icons: ["submit"],
               nextQuestion: [999],
               multiChoice: false
        
        ),
        Question(
              currentQuestion: 11,
              title: "Rate your state of focus just before this survey",
              identifier: "activity-category",
              options: [
                  "Very distracted",
                  "Distracted",
                  "Lightly distracted",
                  "Neutral",
                  "Lightly focused",
                  "Focused",
                  "Deeply, effortly in flow"
              ],
              icons: [
                  "distracted",
                  "distracted",
                  "distracted",
                  "bored",
                  "focus",
                  "focus",
                  "focus"
              ],
              nextQuestion: [
                  12,
                  12,
                  12,
                  12,
                  12,
                  12,
                  12
              ],
              multiChoice: false
        ),
        Question(
              currentQuestion: 12,
              title: "How much of the time were you in a flow state since your last survey? (show 0-100%)",
              identifier: "activity-category",
              options: [
                  "0%",
                  "10%",
                  "20%",
                  "30%",
                  "40%",
                  "50%",
                  "60%",
                  "70%",
                  "80%",
                  "90%",
                  "100%"
                  
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  13,
                  13,
                  13,
                  13,
                  13,
                  13,
                  13,
                  13,
                  13,
                  13,
                  13
              ],
              multiChoice: false
        ),
        
        Question(
              currentQuestion: 13,
              title: "How long do you think it's been since you last completed a survey?",
              identifier: "activity-category",
              options: [
                  "0-30 min",
                  "30-60 min",
                  "60-90 min",
                  "90-120 min",
                  ">120 min"
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  14,
                  15,
                  16,
                  17,
                  1
              ],
              multiChoice: false
        ),
        
        Question(
              currentQuestion: 14,
              title: "More detailly, how long do you think it's been since you last completed a survey?",
              identifier: "activity-category",
              options: [
                  "Less than 10 min",
                  "10-15 min",
                  "16-20 min",
                  "20-25 min",
                  "26-30 min"
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  1,
                  1,
                  1,
                  1,
                  1
              ],
              multiChoice: false
        ),
        
        Question(
              currentQuestion: 15,
              title: "More detailly, how long do you think it's been since you last completed a survey?",
              identifier: "activity-category",
              options: [
                  "31-35 min",
                  "36-40 min",
                  "41-45 min",
                  "46-50 min",
                  "51-55 min",
                  "56-60 min",
                  
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  1,
                  1,
                  1,
                  1,
                  1,
                  1
              ],
              multiChoice: false
        ),
        
        Question(
              currentQuestion: 16,
              title: "More detailly, how long do you think it's been since you last completed a survey?",
              identifier: "activity-category",
              options: [
                  "61-65 min",
                  "66-70 min",
                  "71-75 min",
                  "76-80 min",
                  "81-85 min",
                  "86-90 min",
                  
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  1,
                  1,
                  1,
                  1,
                  1,
                  1
              ],
              multiChoice: false
        ),
        
        Question(
              currentQuestion: 17,
              title: "More detailly, how long do you think it's been since you last completed a survey?",
              identifier: "activity-category",
              options: [
                  "91-95 min",
                  "96-100 min",
                  "101-105 min",
                  "106-110 min",
                  "111-115 min",
                  "116-120 min",
                  
              ],
              icons: [
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster",
                  "faster"
              ],
              nextQuestion: [
                  1,
                  1,
                  1,
                  1,
                  1,
                  1
              ],
              multiChoice: false
        ),
        
    ])
]




