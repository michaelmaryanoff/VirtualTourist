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
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var annotations: [MKPointAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            
            for pin in result {
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


}

extension MapViewController: MKMapViewDelegate {
    
    @objc func addAnnotation(sender: UILongPressGestureRecognizer) {
        // Adapted from StackOverflow post
        let recognizedPoint: CGPoint = sender.location(in: mapView)
        let recognizedCoordinate: CLLocationCoordinate2D = mapView.convert(recognizedPoint, toCoordinateFrom: mapView)
        
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = recognizedCoordinate.latitude
        newPin.longitude = recognizedCoordinate.longitude
        do {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: newPin.latitude, longitude: newPin.longitude)
            annotations.append(annotation)
            mapView.addAnnotation(annotation)
            try dataController.viewContext.save()
        } catch {
            print("nope")
        }
        
        
      
        
        
    }

}

