//
//  FlikrClient.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/29/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import Foundation

class FlikrClient {
    
    // MARK: - Constants
    struct RequestConstants {
        static let baseURLString = "https://www.flickr.com/services/rest/"
        static let method = "?method=flickr.photos.search"
        static let apiKey = "&api_key=cfcda78c06f98952812fc893f4c92f24"
        static let radius = "&radius=10"
        static let extras = "&extras=url_h"
        static let format = "&format=json"
        static let noJsonCallBack = "&nojsoncallback=1"
        static let perPage = "&per_page=30"
    }
    
    // MARK: - API request functions
    func requestPages(lat: Double, long: Double, completion: @escaping(Bool, Int?, Error?) -> Void) {
        
        let url = RequestConstants.baseURLString + RequestConstants.method + RequestConstants.apiKey + "&lat=\(lat)" + "&lon=\(long)" + RequestConstants.radius + RequestConstants.extras + RequestConstants.format + RequestConstants.noJsonCallBack
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
                    print("could not initialize dictionary")
                    return
                }
                
                for (key, value) in jsonDict {
                    if key == "photos" {
                        for (key, value) in value as! [String:Any] {
                            if key == "pages" {
                                let pages = value as! Int
                                completion(true, pages, nil)
                            }
                        }
                    } else {
                        print("this key does not exist in \(#function) 1")
                    }
                    
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
        
    }
    
    func requestPhotos(lat: Double, long: Double, randomPage: Int, completion: @escaping(Bool, [String]?, Error?) -> Void) {
        
        let url = RequestConstants.baseURLString + RequestConstants.method + RequestConstants.apiKey + "&lat=\(lat)" + "&lon=\(long)" + RequestConstants.radius + RequestConstants.extras + RequestConstants.perPage + "&page=\(randomPage)" +  RequestConstants.format + RequestConstants.noJsonCallBack
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
                    print("could not initialize jsonDict")
                    return
                }
                
                guard let photos = jsonDict["photos"] as? [String:Any] else {
                    print("could not initialize photos")
                    return
                }

                guard let photosArray = photos["photo"] as? [[String:Any]] else {
                    print("could not initialize photos 2")
                    return
                }
        
                    for photoItem in photosArray {
                        if let newPhoto = self.getUrl(fromJSON: photoItem) {
                            stringArray.append(newPhoto)
                            // moved this into the loop
                        }
                        
                    }
                
                DispatchQueue.main.async {
                    completion(true, stringArray, nil)
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
    }
    
    // MARK: - Helper functions
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
    
    // Creates singleton class
    class func shared() -> FlikrClient {
        struct Singleton {
            private init() {}
            static var shared = FlikrClient()
        }
        return Singleton.shared
    }
}
