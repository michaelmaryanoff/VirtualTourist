//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/24/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class MapViewController: UIViewController {
    
    var dataController: DataController!
    
    var pins: [Pin] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
            
        }
        
    }


}

extension MapViewController: MKMapViewDelegate {
    
}

