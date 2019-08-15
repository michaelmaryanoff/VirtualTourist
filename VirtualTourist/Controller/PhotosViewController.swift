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
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        
        initalizeAnnotationsArray()
        retrievePhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        retrievePhotos()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        do {
            try self.dataController.viewContext.save()
        } catch {
        print("Could not save before exiting")
        }
        
    }
    
    func retrievePhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        fetchRequest.predicate = predicate
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            
            if result.isEmpty {
                print("the results are empty")
                makeNetworkCall()
            } else {
                print("the results are not empty so we will set the photosarray to the result")
                print(result)
                photosArray = result
                DispatchQueue.main.async {
                    print("called reload in retrieve")
                    self.collectionView.reloadData()
                }
                
            }
            
        }
        
    }
    
    @IBAction func generateNewCollection(_ sender: UIButton) {
        for photo in photosArray {
            dataController.viewContext.delete(photo)
            do {
                try self.dataController.viewContext.save()
            } catch {
                print("could not delete these photos")
            }
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        photosArray = []
        photoStringArray = []
        makeNetworkCall()
    }
    
    fileprivate func makeNetworkCall() {
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude) { (success, photoUrls, error) in
            print("network call made")
            if error != nil {
                print("This is the error: \(error!.localizedDescription)")
                return
            }
            
            if success {
                print("success in network call")
                guard let photosUrls = photoUrls else {
                    print("We could not find any URLs")
                    return
                }
                
                self.photoStringArray = photosUrls
                print("here is the new photoStringArray count after network call: \(self.photoStringArray.count)")
                
                for photoItem in self.photoStringArray {
                    
                    DispatchQueue.main.async {
                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photoItem
                        newPhoto.pin?.latitude = self.passedPin.latitude
                        newPhoto.pin?.longitude = self.passedPin.longitude
                        
                        self.photosArray.append(newPhoto)
                        do {
                            //print("saved in photosArray.append")
                            try self.dataController.viewContext.save()
                        } catch  {
                            print("could not save!")
                        }
                        
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

    
    func urlToData(urlString: String, completion: @escaping (_ data: Data?) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    completion(imgData)
                    //moved this down
                    
                })
            }
        }
    }
    
    func dataToImage(theData: Data, completion: @escaping (_ image: UIImage) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            if let newData = UIImage(data: theData) {
                
                
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    
                    
                    completion(newData)
                    //moved this down
                }
                    
                
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
            generateNewCollectionButton.isEnabled = false
            cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
            cell.imageView!.image = UIImage(data: imagePath.image!)
            cell.endAnimating()
            generateNewCollectionButton.isEnabled = true
        } else {
            cell.beginAnimating()
            generateNewCollectionButton.isEnabled = false
            cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
            if let urlAtImagePath = imagePath.url {
                
                urlToData(urlString: urlAtImagePath) { (data) in
                    
                    if let data = data  {
                        imagePath.image = data
                        cell.imageView!.image = UIImage(data: data)
                        // Maybe move this out of optional block
                        cell.endAnimating()
                        self.generateNewCollectionButton.isEnabled = true
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
        print("selectedPhoto \(selectedPhoto)")
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


