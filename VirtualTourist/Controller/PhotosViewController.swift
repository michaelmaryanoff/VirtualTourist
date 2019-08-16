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
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var generateNewCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.generateNewCollectionButton.isEnabled = true
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        initalizeAnnotationsArray()
        retrievePhotos()
    }
    
    func retrievePhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        fetchRequest.predicate = predicate
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            
            if result.isEmpty {
                makeNetworkCall()
            } else {
                photosArray = result
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    
                }
                
            }
        }
        
    }
    
    @IBAction func generateNewCollection(_ sender: UIButton) {
        generateNewCollectionButton.isEnabled = false
        deleteAllPhotos()
        photosArray = []
        photoStringArray = []
        self.makeNetworkCall()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }

    }
    
    fileprivate func deleteAllPhotos() {
        for photo in photosArray {
            dataController.viewContext.delete(photo)
            do {
                try self.dataController.viewContext.save()
            } catch {
                print("could not delete these photos")
            }
        }
    }
    
    fileprivate func makeNetworkCall() {
        
        photoStringArray = []
        photosArray = []
        
        FlikrClient.shared().requestPages(lat: passedPin.latitude, long: passedPin.longitude) { (success, numberOfPages, error) in
            
            if error != nil {
                print(error?.localizedDescription)
            }
            
            guard let numberOfPages = numberOfPages else {
                return
            }
            
            
        let randomPage = Int.random(in: 0...numberOfPages)
            
        FlikrClient.shared().requestPhotos(lat: self.passedPin.latitude, long: self.passedPin.longitude, randomPage: randomPage) { (success, photoUrls, error) in
            
            if error != nil {
                print("This is the error: \(error!.localizedDescription)")
                return
            }
            
            if success {
                guard let photosUrls = photoUrls else {
                    print("not photo URLs")
                    return
                }
                
                self.photoStringArray = []
                self.photosArray = []
                self.photoStringArray = photosUrls
             
                for photoItem in photosUrls {
                    
                        var newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photoItem
                        newPhoto.pin?.latitude = self.passedPin.latitude
                        newPhoto.pin?.longitude = self.passedPin.longitude
                        self.photosArray.append(newPhoto)
                    
                        if self.photosArray.count != photosUrls.count {
                            print("not equal")
                            DispatchQueue.main.async {
                                self.generateNewCollectionButton.isEnabled = false
                            }
                            
                        } else {
                            self.generateNewCollectionButton.isEnabled = true
                        }
                       
                        do {
                            try self.dataController.viewContext.save()
                        } catch  {
                            print("could not save!")
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
    }

    
    func urlToData(urlString: String, completion: @escaping (_ data: Data?) -> Void){
        
        DispatchQueue.global(qos: .background).async { () -> Void in
            
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {
                
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
        
        let imagePath = photosArray[indexPath.row]
        
        if imagePath.image != nil {
            cell.beginAnimating()
            cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
            cell.imageView!.image = UIImage(data: imagePath.image!)
            cell.endAnimating()
        } else {
            cell.beginAnimating()
            cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
            
            if let urlAtImagePath = imagePath.url {
                urlToData(urlString: urlAtImagePath) { (data) in
                    
                    if let data = data  {
                        imagePath.image = data
                        cell.imageView!.image = UIImage(data: data)
                      
                        cell.endAnimating()
                        DispatchQueue.main.async {
                            self.generateNewCollectionButton.isEnabled = true
                        }
                        

                    }
                    imagePath.pin = self.passedPin
                    
                    do {
                        try self.dataController.viewContext.save()
                    } catch {
                        print("could not save photos in \(#function)")
                    }
                    
                }
                
                
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = self.photosArray[indexPath.row]
        self.dataController.viewContext.delete(selectedPhoto)
        self.photosArray.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        do {
            try self.dataController.viewContext.save()
        } catch {
            print("cannot delete")
        }
        
        self.collectionView.reloadData()
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
    
    func initalizeAnnotationsArray() {
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


