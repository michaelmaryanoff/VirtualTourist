//
//  MapViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 9/26/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import MapKit

extension MapViewController: MKMapViewDelegate {
    
    
    @objc func addAnnotation(sender: UILongPressGestureRecognizer) {
    
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
    }
    
    func addLongPressGestureRecognizer() {
        
        // Adds a gesture recognizers to the map
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    
    
}

