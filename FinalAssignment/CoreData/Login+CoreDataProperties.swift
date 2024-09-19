//
//  Login+CoreDataProperties.swift
//  FinalAssignment
//
//  Created by Deep Vora on 09/09/24.
//
//

import Foundation
import CoreData


extension Login {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Login> {
        return NSFetchRequest<Login>(entityName: "Login")
    }
//
//    @NSManaged public var token: String?
//    @NSManaged public var username: String?

}

extension Login : Identifiable {

}
