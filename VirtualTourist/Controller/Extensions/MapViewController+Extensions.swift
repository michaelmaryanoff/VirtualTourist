//
//  MapViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 9/26/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import MapKit

// MARK: - MKMapViewDelegate functions
extension MapViewController: MKMapViewDelegate {
    
    // MARK: Primary MapView functions
    @objc func addAnnotation(sender: UILongPressGestureRecognizer) {
    
        if sender.state == .began {
            
            // Translate touch into a CGPoint
            let recognizedCoordinate = createNewCoordinate(sender: sender)
            
            // Creates a new NSManagedObject based off of the tapped coordinate
            let newPin = createNewPin(withCoordinate: recognizedCoordinate)
            
            // Adds pin with relevant information to annotation array
            let annotation = createNewAnnotation(withPin: newPin)
            
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
        
        let checkedLatitude = Double(view.annotation?.coordinate.latitude ?? 0)
        let checkedLongitude = Double(view.annotation?.coordinate.longitude ?? 0)
        
        for pin in pinArray {
            if pin.latitude == checkedLatitude && pin.longitude == checkedLongitude {
                self.performSegue(withIdentifier: "presentPhotosCollection", sender: pin)
                return
            }
        }
    }
    
    // MARK: - Helper functions
    func createNewPin(withCoordinate recognizedCoordinate: CLLocationCoordinate2D) -> Pin {
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = recognizedCoordinate.latitude
        newPin.longitude = recognizedCoordinate.longitude
        return newPin
    }
    
    func createNewCoordinate(sender: UILongPressGestureRecognizer) -> CLLocationCoordinate2D {
        let recognizedPoint: CGPoint = sender.location(in: mapView)
        let recognizedCoordinate: CLLocationCoordinate2D = mapView.convert(recognizedPoint, toCoordinateFrom: mapView)
        return recognizedCoordinate
    }
    
    func createNewAnnotation(withPin pin: Pin) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        return annotation
        
    }
    
    func addLongPressGestureRecognizer() {
        
        // Adds a gesture recognizers to the map
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    
    
}

