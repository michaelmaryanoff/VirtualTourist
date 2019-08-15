//
//  FlikrClient.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/29/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import Foundation

class FlikrClient {
    
    var dataController: DataController!
    
    struct RequestConstants {
        static let baseURLString = "https://www.flickr.com/services/rest/"
        static let apiKey = "api_key=cfcda78c06f98952812fc893f4c92f24"
        static let method = "method=flickr.photos.search"
        static let radius = "radius=10"
        static let extras = "extras=url_h"
    }
    
    func requestPages(lat: Double, long: Double, completion: @escaping(Bool, Int?, Error?) -> Void) {
        
        let url = RequestConstants.baseURLString + "?" + RequestConstants.method + "&" + RequestConstants.apiKey + "&" + "lat=\(lat)" + "&" + "lon=\(long)" + "&" + RequestConstants.radius + "&" + RequestConstants.extras + "&format=json" + "&nojsoncallback=1"
        let request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("error is not nil in \(#function): \(error!.localizedDescription)")
                completion(false, 0, error)
            }
            
            guard let data = data else {
                completion(false, 0, error)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                
                guard let jsonDict = json as? [String:Any] else {
                    print("guard 1")
                    return
                }
                
                for (key, value) in jsonDict {
                    if key == "photos" {
                        for (key, value) in value as! [String:Any] {
                            if key == "pages" {
                                let pages = value as! Int
                                //print("we got some pages in \(#function): \(pages)")
                                completion(true, pages, nil)
                            }
                        }
                    } else {
                        //print("this key does not exist in \(#function) 1")
                    }
                    
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
        
    }
    
    func requestPhotos(lat: Double, long: Double, completion: @escaping(Bool, [String]?, Error?) -> Void) {
        
        self.requestPages(lat: lat, long: long) { (success, numberOfPages, error) in
            
            guard let numberOfPages = numberOfPages else {
                print("numberOfpages returned nil")
                return
            }
            if success {
                //print("numberOfPages found: \(numberOfPages)")
            }
            
            let randomPage = Int.random(in: 1...numberOfPages)
            //print("randomPagePassedThrough: \(randomPage)")
        
        let url = RequestConstants.baseURLString + "?" + RequestConstants.method + "&" + RequestConstants.apiKey + "&" + "lat=\(lat)" + "&" + "lon=\(long)" + "&" + RequestConstants.radius + "&" + RequestConstants.extras + "&per_page=30" + "&page=\(randomPage)" +  "&format=json" + "&nojsoncallback=1"
        let request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("error is not nil: \(error!.localizedDescription)")
                completion(false, [], error)
            }
            
            guard let data = data else {
                completion(false, [], error)
                return
            }
            
            do {
                var stringArray = [String]()
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                
                guard let jsonDict = json as? [String:Any] else {
                    print("guard 1")
                    return
                }
                
//                print(jsonDict)
                
                guard let photos = jsonDict["photos"] as? [String:Any] else {
                    print("guard 2")
                    return
                }

                
                guard let photosArray = photos["photo"] as? [[String:Any]] else {
                    print("guard 3")
                    return
                }
                
                for photoItem in photosArray {
                    if let newPhoto = self.getUrl(fromJSON: photoItem) {
                        stringArray.append(newPhoto)
                    }
                    
                }
                
                completion(true, stringArray, nil)
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
        }
    }
    
    func getUrl(fromJSON json: [String:Any]) -> String? {
        guard let urlString = json["url_h"] as? String else {
            return nil
        }
        return urlString
    }
    
    func getNumberOfPages(fromJSON json: [String:Any]) -> String? {
        guard let pagesString = json["pages"] as? String else {
            return nil
        }
        return pagesString
    }
    
    class func shared() -> FlikrClient {
        struct Singleton {
            private init() {}
            static var shared = FlikrClient()
        }
        return Singleton.shared
    }
}
