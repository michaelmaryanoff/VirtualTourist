//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/30/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController {
    
    // MARK: - Managed Core Data variables
    var dataController: DataController!
    var passedPin: Pin!
    var photosArray: [Photo] = []

    // MARK: - Non-managed variables
    var photoStringArray: [String] = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var generateNewCollectionButton: UIButton!
    
    // MARK: - Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        mapView.delegate = self
        
        self.generateNewCollectionButton.isEnabled = true
        
        initalizeAnnotationsArray()
        retrievePhotos()
    }
    
    // MARK: - IBActions
    @IBAction func generateNewCollection(_ sender: UIButton) {
        generateNewCollectionButton.isEnabled = false
        resetPhotos()
    }
    
    // MARK: - Photo functions
    func resetPhotos() {
        deleteAllPhotos()
        photosArray = []
        photoStringArray = []
        self.makeNetworkCall()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
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
    
    // MARK: - Networking functions
    fileprivate func makeNetworkCall() {
        
        photoStringArray = []
        photosArray = []
        
        FlikrClient.shared().requestPages(lat: passedPin.latitude, long: passedPin.longitude) { (success, numberOfPages, error) in
            
            if error != nil {
                print(error?.localizedDescription ?? "There was an error")
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
                    
                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.url = photoItem
                        newPhoto.pin?.latitude = self.passedPin.latitude
                        newPhoto.pin?.longitude = self.passedPin.longitude
                        self.photosArray.append(newPhoto)
                    
                        if self.photosArray.count != photosUrls.count {
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




