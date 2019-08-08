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
    
    var isFirstTimeLoading: Bool = false
    
    var photoStringArray: [String] = []
    
    var photosArray: [Photo] = []
    
    var imageArray: [UIImage] = []
    
    var numberOfLoops = 0
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(passedPin)
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        
//        setupFetchedResultsController()
        
        print(photoStringArray)
        print(photosArray)
        
        initalizeArray()
        
        
//        setupFetchedResultsController()
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
//        let predicate = NSPredicate(format: "pin == %@", self.passedPin)
        let predicate = NSPredicate(format: "pin.latitude == %@", passedPin.latitude, "pin.latitude == %@", passedPin.latitude)
        fetchRequest.predicate = predicate
        
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                
                print("result \(result)")
                photosArray = result
                print("newPhotosArry: \(photosArray)")
            
                for photo in photoStringArray {

                    self.urlToImage(urlString: photo, completion: { (data) in

                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photo
                        newPhoto.image = data
                        newPhoto.pin = self.passedPin
                        self.photosArray.append(newPhoto)
                        self.photoStringArray.append(newPhoto.url!)
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("not happening")
                        }

                    })
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        return
                    }
                    do {
                        try self.dataController.viewContext.save()
                    } catch {
                        print("not happening")
                    }
                    
                   


                }
                
            }
        print(photosArray)
        
        makeNetworkCall()
        print(photosArray)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        setupFetchedResultsController()
    }
    
    fileprivate func makeNetworkCall() {
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            print("made network call")
            if success {
                guard let photosUrls = photoUrls else {
                    return
                }
                
                var newPhotosArray: [Photo] = []
                var stringArray = photosUrls
                
                
                    for photo in stringArray {
                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photo
                        newPhoto.pin = self.passedPin
                        newPhotosArray.append(newPhoto)
                        self.photosArray.append(newPhoto)
                        self.photosArray.append(newPhoto)
                        self.photoStringArray.append(newPhoto.url!)
                        self.photosArray = newPhotosArray
                        print(newPhotosArray)
                        do {
                            
                            print("new photos array: \(self.photosArray)")
                            try self.dataController.viewContext.save()
                        } catch {
                            print("not happening")
                        }
                        
                        
                    }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                
                do {
                    try self.dataController.viewContext.save()
                } catch {
                    print("not happening")
                }
            } else {
                print("error in call")
            }
        }
    }
//
//    fileprivate func setupFetchedResultsController() {
//
//        var fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
//        let predicate = NSPredicate(format: "pin == %@", passedPin)
//        fetchRequest.predicate = predicate
//        fetchRequest.sortDescriptors = []
//
//        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
//
//        do {
//            try fetchedResultsController.performFetch()
//            print("has been fetched")
//        } catch {
//            print("no fetchy")
//        }
//    }
    
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
                    print("imgData: \(imgData)")
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
        
        if let urlString = photosArray[indexPath.row].url {
            let url = URL(string: urlString)
            
            if let url = url {
                let data = try? Data(contentsOf: url)
                
                if let data = data {
                    cell.imageView.image = UIImage(data: data)
                }
            }
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
        print("\(#function) called")
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


