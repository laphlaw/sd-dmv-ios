//
//  Vehicle+CoreDataProperties.swift
//  sd-dmv
//
//  Created by neil on 10/7/24.
//
//

import Foundation
import CoreData


extension Vehicle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vehicle> {
        return NSFetchRequest<Vehicle>(entityName: "Vehicle")
    }

    @NSManaged public var color: String?
    @NSManaged public var date: Date
    @NSManaged public var imageData: Data?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var make: String?
    @NSManaged public var model: String?
    @NSManaged public var plateNumber: String
    @NSManaged public var state: String
    @NSManaged public var year: Int16

}

extension Vehicle : Identifiable {

}
