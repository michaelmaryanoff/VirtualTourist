//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/30/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    var dataController: DataController!
    
    var passedPin: Pin!
    
    var photoStringArray: [String] = []
    var photosArray: [Photo] = []
    var imageArray: [UIImage] = []
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initalizeArray()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        
        var fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
//
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        do {
//            try fetchedResultsController.performFetch()
            let result = try dataController.viewContext.fetch(fetchRequest)
            
            photosArray = result
            
            print("result: \(result)")
            
        } catch {
            print("no fetchy")
        }
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            if success {
                
                guard let photosUrls = photoUrls else {
                    return
                }
                
                var stringArray = photosUrls
                
                for photo in stringArray {
                    
                    self.urlToImage(urlString: photo, completion: { (data) in

                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photo
                        newPhoto.image = data
                        newPhoto.pin = self.passedPin
                        do {
                            self.photosArray.append(newPhoto)
                            self.photoStringArray.append(newPhoto.url!)
                            // self.imageArray.append(image)
                            try self.dataController.viewContext.save()
                            
                            print(self.photosArray)
                        } catch {
                            print("no")
                        }
                        
                    })
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                
            } else {
                print("error in call")
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func urlToImage(urlString: String, completion: @escaping (_ data: Data) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            // get the url
            // get the NSData
            // turn it into a UIImage
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {
                // run the completion block
                // always in the main queue, just in case!
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(imgData)
                })
            }
        }
    }
    

}

//MARK: - Collection view Functions


extension PhotosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "customCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CustomCell
        
//        cell.imageView.image = imageArray[indexPath.row]
        
        if let imageData = photosArray[indexPath.row].image {
            cell.imageView.image = UIImage.init(data: imageData)
        }
        
        return cell
    }
    
}

// MARK: - Map functions

extension PhotosViewController: MKMapViewDelegate {
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func initalizeArray() {
        var passedPinLat = passedPin.latitude
        var passedPinLong = passedPin.longitude
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
    
}


