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
        
        setupFetchedResultsController()
        
            FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
                //            if success {
                
                guard let photoUrls = photoUrls else {
                    print("No photos!")
                    return
                }
                
                self.photoStringArray = photoUrls
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                
//                for individualPhoto in photoUrls {
//                    var newPhoto = Photo(context: self.dataController.viewContext)
//                    newPhoto.url = individualPhoto
//                    self.urlToImage(urlString: individualPhoto, completion: { (data) in
//                        newPhoto.image = data
//                        self.photosArray.append(newPhoto)
//                        print(self.photosArray)
//                        do {
//                            try self.dataController.viewContext.save()
//                        } catch {
//                            print("not gonna happen chief")
//                        }
//                    })
//                }
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
                
                
                
                print("if called: \(self.photosArray)")
                
            }
            
    
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
//        if photosArray.isEmpty {
//
//        } else {
//
//            print("else called: \(photosArray)")
//
//        if let result = try? dataController.viewContext.fetch(fetchRequest) {
//
//            for photo in result {
//
//                self.urlToImage(urlString: photo.url!, completion: { (data) in
//
//                    let newPhoto = Photo(context: self.dataController.viewContext)
//                    newPhoto.url = photo.url!
//                    newPhoto.image = data
//                    newPhoto.pin = self.passedPin
//                    self.photosArray.append(newPhoto)
//                    self.photoStringArray.append(newPhoto.url!)
//                    self.imageArray.append(UIImage(data: data)!)
//                    print("Did the data controller change? \(self.dataController.viewContext.hasChanges)")
//                    do {
//                        try self.dataController.viewContext.save()
//                    } catch {
//                        print("not happening")
//                    }
//
//                })
//                print("Did the data controller change? \(self.dataController.viewContext.hasChanges)")
//                do {
//                    try self.dataController.viewContext.save()
//                } catch {
//                    print("not happening")
//                }
//
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//
//            }
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//
//        }
//
//    }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            //            if success {
            
            guard let photoUrls = photoUrls else {
                print("No photos!")
                return
            }
            
            self.photoStringArray = photoUrls
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
            
            
            print("if called: \(self.photosArray)")
            
        }
        
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            
            photosArray = result

        } catch {
            print("no fetchy")
        }
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
                    print(imgData)
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
        
//        let imageData = photosArray[indexPath.row]
        
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
        let passedPinLat = passedPin.latitude
        let passedPinLong = passedPin.longitude
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


