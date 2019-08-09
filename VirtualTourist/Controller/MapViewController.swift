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
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            print("Pin result: \(result)")
            
            pinArray = result
            
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }


}

extension MapViewController: MKMapViewDelegate {
    
    @objc func addAnnotation(sender: UILongPressGestureRecognizer) {
        // Adapted from StackOverflow post
        
        // Translate touch into a CGPoint
        let recognizedPoint: CGPoint = sender.location(in: mapView)
        let recognizedCoordinate: CLLocationCoordinate2D = mapView.convert(recognizedPoint, toCoordinateFrom: mapView)
        
        // Creates a new NSManagedObject based off of the tapped coordinate
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = recognizedCoordinate.latitude
        newPin.longitude = recognizedCoordinate.longitude
        
        do {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: newPin.latitude, longitude: newPin.longitude)
            var locationForGeocoding = CLLocation(latitude: newPin.latitude, longitude: newPin.longitude)
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
            annotations.append(annotation)
            pinArray.append(newPin)
            mapView.addAnnotation(annotation)
            try dataController.viewContext.save()
        } catch {
            print("nope")
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

