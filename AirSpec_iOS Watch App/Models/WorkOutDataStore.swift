//
//  WorkOutDataStore.swift
//  AirSpec_iOS Watch App
//
//  Created by ZhongS on 3/13/23.
//

import Foundation
import Combine
import HealthKit

struct WorkoutDataStore {
    
    var builder: HKLiveWorkoutBuilder
    var session: HKWorkoutSession
    
    init(){
        let healthStore = HKHealthStore()
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        
        session = try! HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        builder = session.associatedWorkoutBuilder()
    }
    
        func startWorkoutSession(){
            
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { (success, error) in
                
                guard success else {
                    return
                }
                // Indicate that the session has started.
            }
            
        }
    
        func stopWorkoutSession(){
            session.end()
            builder.endCollection(withEnd: Date()) { (success, error) in
                
                guard success else {
                    return
                }
                self.builder.finishWorkout { (workout, error) in
                    
                    guard workout != nil else {
                        return
                    }
                    
                }
            }
        }
  
  }
