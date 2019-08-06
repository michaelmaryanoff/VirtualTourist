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
        setupFetchedResultsController()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        
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
            mapView.addAnnotation(annotation)
            try dataController.viewContext.save()
        } catch {
            print("nope")
        }
        
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentPhotosCollection" {
            
            let destinationVC = segue.destination as! PhotosViewController
            
            destinationVC.passedPin = sender as! Pin
            destinationVC.dataController = dataController
         
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var passedPin = Pin(context: dataController.viewContext)
        passedPin.latitude = Double(view.annotation?.coordinate.latitude ?? 0)
        passedPin.longitude = Double(view.annotation?.coordinate.longitude ?? 0)
//        print("Map VC passed pin is: \(passedPin.latitude), and \(passedPin.longitude)")
    
        self.performSegue(withIdentifier: "presentPhotosCollection", sender: passedPin)
    }
    

    
    

}

