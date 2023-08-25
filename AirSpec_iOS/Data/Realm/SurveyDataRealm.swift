//
//  SurveyDataRealm.swift
//  AirSpec_iOS
//
//  Created by Anna Yang on 8/17/23.
//

import Foundation
import RealmSwift

class SurveyDataRealm: Object, ObjectKeyIdentifiable{
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var binaryRecord: Data?
}
