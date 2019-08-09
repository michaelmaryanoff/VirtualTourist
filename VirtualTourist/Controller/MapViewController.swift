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

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var annotations: [MKPointAnnotation] = []
    
    var pinArray: [Pin] = []
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the map view delegate
        mapView.delegate = self
        
        // Adds a gesture recognizers to the map
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Creates a fetch request
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
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
                
                print("pinArray.count: \(pinArray.count)")
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }


}

extension MapViewController: MKMapViewDelegate {
    
    @objc func addAnnotation(sender: UILongPressGestureRecognizer) {
        // Adapted from StackOverflow post
        
        if sender.state == .began {
        
        // Translate touch into a CGPoint
        let recognizedPoint: CGPoint = sender.location(in: mapView)
        let recognizedCoordinate: CLLocationCoordinate2D = mapView.convert(recognizedPoint, toCoordinateFrom: mapView)
        
        // Creates a new NSManagedObject based off of the tapped coordinate
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = recognizedCoordinate.latitude
        newPin.longitude = recognizedCoordinate.longitude
        
        // Adds pin with relevant information to annotation array
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: newPin.latitude, longitude: newPin.longitude)
        var locationForGeocoding = CLLocation(latitude: newPin.latitude, longitude: newPin.longitude)
        
        // Comes up with an place name and adds it to new pin
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(locationForGeocoding) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    
                    // Have some restrictions on locality
                    var locationString = placemark.locality ?? "Could not determine locality"
                    newPin.placeName = locationString
                }
            }
        }
        
        // Appends to relevant arrays
        annotations.append(annotation)
        pinArray.append(newPin)
        
        
        mapView.addAnnotation(annotation)
        do {
            try dataController.viewContext.save()
        } catch {
            print("nope")
        }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        var checkedLatitude = Double(view.annotation?.coordinate.latitude ?? 0)
        var checkedLongitude = Double(view.annotation?.coordinate.longitude ?? 0)
        
        for pin in pinArray {
            if pin.latitude == checkedLatitude && pin.longitude == checkedLongitude {
                self.performSegue(withIdentifier: "presentPhotosCollection", sender: pin)
                return
            }
        }
//        print("Map VC passed pin is: \(passedPin.latitude), and \(passedPin.longitude)")
        
        
    
        
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentPhotosCollection" {
            
            let destinationVC = segue.destination as! PhotosViewController
            
            destinationVC.passedPin = sender as! Pin
            destinationVC.dataController = dataController
            
        }
    }
    

    
    

}

