//
//  RawSensorData.swift
//  AirSpec_iOS
//
//  Created by ZhongS on 5/11/23.
//

import Foundation
import RealmSwift

class RawSensorData: Object, ObjectKeyIdentifiable{
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var binaryRecord: Data?
}
