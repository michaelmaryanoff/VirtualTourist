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
    
    func requestPhotos(lat: Double, long: Double, completion: @escaping(Bool, [String]?, Error?) -> Void) {
        var url = RequestConstants.baseURLString + "?" + RequestConstants.method + "&" + RequestConstants.apiKey + "&" + "lat=\(lat)" + "&" + "lon=\(long)" + "&" + RequestConstants.radius + "&" + RequestConstants.extras + "&per_page=4" + "&format=json" + "&nojsoncallback=1"
        var tmpUrl = "https://jsonplaceholder.typicode.com/photos"
        var request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            print(url)
            
            guard let data = data else {
                completion(false, [], error)
                return
            }
            
//            print(String(data: data, encoding: .utf8)!)
            do {
                var stringArray = [String]()
                var json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                
                guard let jsonDict = json as? [AnyHashable:Any] else {
                    print("guard 1")
                    return
                }
                
                guard let photos = jsonDict["photos"] as? [String:Any] else {
                    print("guard 2")
                    return
                }
//                print(photos)
                
                
                guard let photosArray = photos["photo"] as? [[String:Any]] else {
                    print("guard 3")
                    return
                }
                
//                print("photosarray: \(photos)")
                
                
                for photoItem in photosArray {
                    if let newPhoto = self.getUrl(fromJSON: photoItem) {
                        stringArray.append(newPhoto)
                    }
                    
                }
//                print("stringarray: \(stringArray)")
                
                completion(true, stringArray, nil)
                
            } catch {
                print(error.localizedDescription)
            }
            
            
            
        }
        task.resume()
    }
    
    func getUrl(fromJSON json: [String:Any]) -> String? {
        guard let urlString = json["url_h"] as? String else {
//            print("could not get string")
            return nil
        }
        return urlString
    }
    
 
    
    class func shared() -> FlikrClient {
        struct Singleton {
            private init() {}
            static var shared = FlikrClient()
        }
        return Singleton.shared
    }
}
