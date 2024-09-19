//
//  Channel+CoreDataProperties.swift
//  FinalAssignment
//
//  Created by Deep Vora on 09/09/24.
//
//

import Foundation
import CoreData


extension Channel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Channel> {
        return NSFetchRequest<Channel>(entityName: "Channel")
    }

    @NSManaged public var groupFolderName: String?
    @NSManaged public var id: String?
    @NSManaged public var name: String?

}

extension Channel : Identifiable {

}
