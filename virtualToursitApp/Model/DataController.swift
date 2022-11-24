//
//  DataController.swift
//  virtualToursitApp
//
//  Created by MACBOOK PRO on 11/24/22.
//

import Foundation

import Foundation
import CoreData

class DataController {
    // create persistent container
    let persistentContainer: NSPersistentContainer
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: "VirtualTourist")
    }
    
    // add convinience property to access context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // load persistent store
    func load(completion: (() -> Void)? = nil){
        persistentContainer.loadPersistentStores {storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
