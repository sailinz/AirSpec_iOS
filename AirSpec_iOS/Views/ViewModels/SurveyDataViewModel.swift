//
//  File.swift
//  AirSpec_iOS
//
//  Created by ZHONG Sailin on 14.02.23.
//

import Foundation
import CoreData

class SurveyDataViewModel: ObservableObject{
    let container: NSPersistentContainer
    
    init(){
        // load core data
        container = NSPersistentContainer(name: "SurveyDataContainer")
        container.loadPersistentStores{(description, error) in
            if let error = error{
                print("ERROR LOADING CORE DATA. \(error)")
            }else {
                print("Successfully loaded core data!")
            }
            
        }
    }
}
     
