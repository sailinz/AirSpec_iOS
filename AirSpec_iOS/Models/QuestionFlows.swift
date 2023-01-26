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
    Flow(title: "Noise and privacy", questions:[
        Question(
            currentQuestion: 0,
            title: "How are you feeling",
            identifier: "overall-comfort",
            options: [
                "Comfy",
                "Not comfy",
            ],
            icons: [
                "mood-good",
                "mood-bad",
            ],
            nextQuestion: [
                4,
                1
            ],
            multiChoice: false
        ),
        Question(
            currentQuestion: 1,
            title: "What do you feel uncomfortable with? (Allow multiple answers)",
            identifier: "discomfort-kind",
            options: [
                "Thermal",
                "Air quality",
                "Lighting",
                "Noise",
                "Mood",
                "Others"
            ],
            icons: [
//                SensorIconConstants.sensorThermal[0].icon,
//                SensorIconConstants.sensorAirQuality[2].icon,
//                SensorIconConstants.sensorVisual[0].icon,
//                SensorIconConstants.sensorAcoustics[0].icon,
                "thermal-privacy",
                "air-quality-smelly",
                "light-bright",
                "noise-privacy",
                "happy",
                "other"
            ],
            nextQuestion: [
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
                  "Noise"
              ],
              icons: [
                  "thermal-privacy",
                  "air-quality-smelly",
                  "light-bright",
                  "noise-privacy"
              ],
              nextQuestion: [
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
        
        )
    ])
]




