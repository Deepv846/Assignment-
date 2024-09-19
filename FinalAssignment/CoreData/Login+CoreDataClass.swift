//
//  Login+CoreDataClass.swift
//  FinalAssignment
//
//  Created by Deep Vora on 09/09/24.
//
//

import Foundation
import CoreData

@objc(Login)
public class Login: NSManagedObject {
    @NSManaged public var username: String?
    @NSManaged public var token: String?
}
