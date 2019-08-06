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
    
//    var dataController = FlikrClient.shared().dataController.viewContext
    
    
    var dataController: DataController!
    
    var passedPin: Pin!
    
    var photoStringArray = [String]()
    var photosArray: [Photo] = []
    var imageArray: [UIImage] = []
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
//    fileprivate func setupFetchedResultsController() {
//        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
////        let predicate = NSPredicate(format: "pin == %@", pin)
//        fetchRequest.sortDescriptors = []
//
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(passedPin)-photos")
//        fetchedResultsController.delegate = self
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
//    }

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initalizeArray()
        
        var newImageArray = [Photo(context: dataController.viewContext)]
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        var fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("no fetchy")
        }
        
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            print("result: \(result)")
            photosArray = result
        }
        
        print("Photos VC passed pin is: \(passedPin.latitude), and \(passedPin.longitude)")
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            if success {
                
                guard let photosUrls = photoUrls else {
                    print("could not fetch")
                    return
                }
                
                self.photoStringArray = photosUrls
                
                // TODO: convert to data with this here, and only convert to image when needed for the collection view
                for photo in self.photoStringArray {
                    
                    self.withBigImage(urlString: photo, completion: { (image) in
//                        self.imageArray.append(image)
                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photo
                        newPhoto.image = UIImage.pngData(image)()
                        do {
                            self.photosArray.append(newPhoto)
                            self.imageArray.append(image)
                            try self.dataController.viewContext.save()
                        } catch {
                            print("no")
                        }
                        self.collectionView.reloadData()
                    })
                }
                
            } else {
                print("error in call")
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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

//MARK: - Collection view Functions


extension PhotosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(photosArray.count)
        return photosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "customCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CustomCell
        
        cell.imageView.image = imageArray[indexPath.row]
        
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


