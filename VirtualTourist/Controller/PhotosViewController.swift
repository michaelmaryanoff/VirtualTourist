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
    
//    var dataController = FlikrClient.shared().dataController.viewContext
    
    var passedPin: TempPin?
    var dataController: DataController!
    
    var photos = [String]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initalizeArray()
//        self.photos = []
        
        
        guard let passedPinLat = passedPin?.latitude else {
            print("passed no pin ")
            return
        }
        
        guard let passedPinLong = passedPin?.longitude else {
            print("passed no pin ")
            return
        }
        
        FlikrClient.shared().requestPhotos(lat: 4.663908, long: -74.044283) { (success, photoUrls, error) in
            if success {
                print("success in call")
                guard let photosUrls = photoUrls else {
                    print("could not fetch")
                    return
                }
                self.photos = photosUrls
                print(photosUrls)
                var firstPhoto = photosUrls[1]
                DispatchQueue.main.async {
                    self.imageView.image = nil
                }
                
                self.withBigImage(urlString: firstPhoto, completion: { (image) in
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }

                })
//                print("photos array at 0: \(self.photos[0])")
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
        guard let passedPinLat = passedPin?.latitude else {
            print("passed no pin ")
            return
        }
        
        guard let passedPinLong = passedPin?.longitude else {
            print("passed no pin ")
            return
        }
        var annotations = [MKPointAnnotation]()
        let lat = CLLocationDegrees(passedPinLat)
        let long = CLLocationDegrees(passedPinLong)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotations.append(annotation)
        self.mapView.addAnnotations(annotations)
        let initialLocation = CLLocation(latitude: lat, longitude: long)
        centerMapOnLocation(location: initialLocation)
        
    }
    
    func withBigImage(urlString: String, completion: @escaping (_ image: UIImage) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            // get the url
            // get the NSData
            // turn it into a UIImage
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url), let img = UIImage(data: imgData) {
                // run the completion block
                // always in the main queue, just in case!
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(img)
                })
            }
        }
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
