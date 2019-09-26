//
//  PhotosViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 9/26/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import UIKit
import MapKit

//MARK: - Collection view Functions
extension PhotosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Main collection view functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "customCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CustomCell
        
        let photo = photosArray[indexPath.row]
        
        if photo.image != nil {
            loadImageInCell(forCell: cell, photo: photo, result: .imageDoesExist)
        } else {
            loadImageInCell(forCell: cell, photo: photo, result: .imageDoesNotExist)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = self.photosArray[indexPath.row]
        
        deleteSelectedPhoto(selectedPhoto: selectedPhoto, indexPath: indexPath)
        
    }
    
    // MARK: Collection view Helper functions
    func deleteSelectedPhoto(selectedPhoto: Photo, indexPath: IndexPath) {

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
    
    enum Result {
        case imageDoesExist
        case imageDoesNotExist
    }
    
    func loadImageInCell(forCell cell: CustomCell, photo: Photo, result: Result) {
        switch result {
            case .imageDoesExist:
                loadExistingImage(cell: cell, photo: photo)
            case .imageDoesNotExist:
                loadNewImage(forCell: cell, photo: photo)
        }
    }
    
    func loadNewImage(forCell cell: CustomCell, photo: Photo) {
        cell.beginAnimating()
        cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
        
        if let urlAtImagePath = photo.url {
            urlToData(urlString: urlAtImagePath) { (data) in
                
                if let data = data  {
                    photo.image = data
                    cell.imageView!.image = UIImage(data: data)
                    
                    cell.endAnimating()
                    DispatchQueue.main.async {
                        self.generateNewCollectionButton.isEnabled = true
                    }
                    
                    
                }
                photo.pin = self.passedPin
                
                do {
                    try self.dataController.viewContext.save()
                } catch {
                    print("could not save photos in \(#function)")
                }
                
            }
            
        }
    }
    
    func loadExistingImage (cell: CustomCell, photo: Photo) {
        cell.beginAnimating()
        cell.imageView.image = UIImage(named: "VirtualTourist_Placeholder")
        cell.imageView!.image = UIImage(data: photo.image!)
        cell.endAnimating()
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
