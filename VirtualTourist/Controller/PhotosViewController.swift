//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/30/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import MapKit

class PhotosViewController: UIViewController {
    
    var dataController: DataController!
    
    var passedLong: Double?
    var passedLat: Double?
    var photos = [String]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initalizeArray()
        FlikrClient.shared().requestPhotos(lat: passedLat ?? 0, long: passedLong ?? 0) { (success, photoUrls, error) in
            if success {
                print("success in call")
                guard let photosUrls = photoUrls else {
                    print("could not fetch")
                    return
                }
                
                self.photos = photosUrls
                print(self.photos)
            } else {
                print("error in call")
            }
        }

        // Do any additional setup after loading the view.
    }
    

}

extension PhotosViewController: MKMapViewDelegate {
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func initalizeArray() {
        var annotations = [MKPointAnnotation]()
        let lat = CLLocationDegrees(passedLat ?? 0)
        let long = CLLocationDegrees(passedLong ?? 0)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotations.append(annotation)
        self.mapView.addAnnotations(annotations)
        let initialLocation = CLLocation(latitude: lat, longitude: long)
        centerMapOnLocation(location: initialLocation)
        
    }
    
    
}

extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(photos.count)
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        return cell
    }

}