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

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        do {
            try self.dataController.viewContext.save()
        } catch {
        print("Could not save before exiting")
        }
        
    }
    
    @IBAction func loadNewCollection(_ sender: UIButton) {
        self.generateNewCollectionButton.isEnabled = false
        for photo in photosArray {
            dataController.viewContext.delete(photo)
            do {
                try self.dataController.viewContext.save()
            } catch {
                print("could not delete these photos")
            }
        }
        
        photosArray = []
        photoStringArray = []
        makeNetworkCall()
        
        // TODO*** Reenable
//        self.collectionView.reloadData()
        
        
    }
    
    func retrievePhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", passedPin)
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            
            if result.isEmpty {
                makeNetworkCall()
            }
            photosArray = result
            
            for photo in result {
                print("Refresh")
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                //moved this out of main
                return
            }
            
        }
        
    }
    
    fileprivate func makeNetworkCall() {
        
        let rangomPage = Int.random(in: 1...10 )
        
        FlikrClient.shared().requestPhotos(lat: passedPin.latitude, long: passedPin.longitude, page: rangomPage) { (success, photoUrls, error) in
            if success {
                
                if error != nil {
                    print("This is the error: \(error!.localizedDescription)")
                    return
                }
                
                guard let photosUrls = photoUrls else {
                    print("We could not find any URLs")
                    return
                }
                
//                var newPhotosArray: [Photo] = []
//                let stringArray = photosUrls
                
                    for photo in photosUrls {
                        self.urlToData(urlString: photo, completion: { (data) in
                            
                            let newPhoto = Photo(context: self.dataController.viewContext)
                            newPhoto.url = photo
                            newPhoto.pin?.latitude = self.passedPin.latitude
                            newPhoto.pin?.longitude = self.passedPin.longitude
                            newPhoto.pin = self.passedPin
                            
                            newPhoto.image = data
                            self.photosArray.append(newPhoto)
                            self.photoStringArray.append(newPhoto.url!)
                            if Int(self.photosArray.count) == Int(photosUrls.count) {
                                self.generateNewCollectionButton.isEnabled = true
                            } else {
                                self.generateNewCollectionButton.isEnabled = false
                            }
                            do {
                                try self.dataController.viewContext.save()
                            } catch {
                                print("not happening")
                            }
                        })
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
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
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
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
        
        //New method, attempting to convert image in background
        
        
        if let imageData = photosArray[indexPath.row].image {
            
            if imageData.isEmpty {
                print("no image data")
            }
            
            self.dataToImage(theData: imageData, completion: { (image) in
                print("still executing")
                
                cell.imageView.image = image
                
                print("done executing")
            })
            
            DispatchQueue.main.async {
                
                self.collectionView.reloadData()
            }
            
        } else {
            
        print("else")
        
        }
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let cell = self.collectionView.cellForItem(at: indexPath) as? CustomCell
//
//        cell?.imageView.image = nil
//    }
    
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


