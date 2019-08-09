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
        
        print("raw pin dat: \(passedPin)")
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        initalizeArray()
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)

        fetchRequest.predicate = predicate
        
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                
                photosArray = result
            
                for photo in photoStringArray {

                    self.urlToData(urlString: photo, completion: { (data) in

                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photo
                        
                        // Should this not be what is there
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
        
        makeNetworkCall()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        do {
        try self.dataController.viewContext.save()
            print("saved in ViewdidDissapear")
        } catch {
            print("could not save!")
        }
        
    }
    
    fileprivate func makeNetworkCall() {
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            print("made network call")
            if success {
                
                if let error = error {
                    print("This is the error: \(error.localizedDescription)")
                    return
                }
                
                guard let photosUrls = photoUrls else {
                    return
                }
                
                var newPhotosArray: [Photo] = []
                var stringArray = photosUrls
                
                
                    for photo in stringArray {
                        
                        self.urlToData(urlString: photo, completion: { (data) in
                            
                            let newPhoto = Photo(context: self.dataController.viewContext)
                            newPhoto.url = photo
                            newPhoto.pin?.latitude = self.passedPin.latitude
                            newPhoto.pin?.longitude = self.passedPin.longitude
                            newPhoto.pin = self.passedPin
                            print("urlToData")
                            newPhoto.image = data
                            print("data \(data)")
                            newPhotosArray.append(newPhoto)
                            self.photosArray.append(newPhoto)
                            self.photoStringArray.append(newPhoto.url!)
                            self.photosArray = newPhotosArray
                            do {
                                print("new photos array before saving: \(self.photosArray)")
                                try self.dataController.viewContext.save()
                            } catch {
                                print("not happening")
                            }
                        })
                        
                    }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            // Deleted a do catch block here
            } else {
                print("error in call")
            }
        }
    }

    
    func urlToData(urlString: String, completion: @escaping (_ data: Data) -> Void){
        
        DispatchQueue.global(qos: .background).async { () -> Void in
            
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {
                
                DispatchQueue.main.async(execute: { () -> Void in
                    print("converted the data!")
                    self.collectionView.reloadData()
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
        
        if let urlImage = photosArray[indexPath.row].image {
            
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(data: urlImage)
                self.collectionView.reloadData()
            }
            
        }
            
        
//        if let urlString = photosArray[indexPath.row].url {
//            let url = URL(string: urlString)
//
//            if let url = url {
//                let data = try? Data(contentsOf: url)
//
//                if let data = data {
//                    cell.imageView.image = UIImage(data: data)
//
//                }
//            }
//        }
        
        do {
            try self.dataController.viewContext.save()
        } catch {
            print("could not save in colllection view")
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


