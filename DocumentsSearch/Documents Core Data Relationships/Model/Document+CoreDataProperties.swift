//
//  Document+CoreDataProperties.swift
//  Documents Core Data Relationships Search
//
//  Created by Dale Musser on 7/10/18.
//  Copyright © 2018 Dale Musser. All rights reserved.
//
//

import Foundation
import CoreData


extension Document {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    @NSManaged public var name: String?
    @NSManaged public var content: String?
    @NSManaged public var size: Int64
    @NSManaged public var rawModifiedDate: NSDate?
    @NSManaged public var category: Category?

}
