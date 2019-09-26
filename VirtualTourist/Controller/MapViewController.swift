//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/24/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    
    
    // MARK: - Managed Core Data variables
    var dataController: DataController!
    var pinArray: [Pin] = []
    
    // MARK: - Non-managed variables
    var annotations: [MKPointAnnotation] = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the map view delegate
        mapView.delegate = self
        
        // Adds a gesture recognizers to the map
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Creates a fetch request
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        makeFetchRequest(fetchRequest)
        
    }
    
    fileprivate func makeFetchRequest(_ fetchRequest: NSFetchRequest<Pin>) {
        // Takes the results of the fetch request
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            
            pinArray = result
            
            // Loops through the new pin array
            for pin in pinArray {
                
                // Creates a new annotation from the results array and adds to annotations
                var loadedAnnotation = MKPointAnnotation()
                let lat = pin.latitude
                let long = pin.longitude
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                loadedAnnotation.coordinate = coordinate
                annotations.append(loadedAnnotation)
                mapView.addAnnotation(loadedAnnotation)
                
                
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentPhotosCollection" {
            let destinationVC = segue.destination as! PhotosViewController
            
            destinationVC.passedPin = sender as! Pin
            destinationVC.dataController = dataController
            
        }
    }


}

